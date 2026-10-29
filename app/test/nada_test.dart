import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nada/app.dart';
import 'package:nada/data/nada_models.dart';
import 'package:nada/data/session_repository.dart';
import 'package:nada/services/nada_notifications.dart';
import 'package:nada/services/nada_widget_service.dart';
import 'package:nada/state/nada_controller.dart';

class MemoryRepository implements SessionRepository {
  NadaStoreData data = const NadaStoreData();

  @override
  Future<NadaStoreData> load() async => data;

  @override
  Future<void> save(NadaStoreData next) async => data = next;
}

class SilentNotifications implements SessionNotifications {
  @override
  bool permissionGranted = true;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> refreshPermission() async {}

  @override
  Future<void> cancelSession() async {}

  @override
  Future<void> cancelGoalAlert() async {}

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<void> scheduleGoal({
    required DateTime endAt,
    required Duration goal,
    required bool notificationsEnabled,
    required bool soundEnabled,
  }) async {}

  @override
  Future<void> showOngoing({
    required NadaMode mode,
    required Duration elapsed,
    Duration? goal,
    required DateTime startedAt,
    required bool notificationsEnabled,
  }) async {}
}

NadaSession sessionAt(
  DateTime start, {
  Duration duration = const Duration(minutes: 25),
  NadaMode mode = NadaMode.free,
  Duration? goal,
  bool completed = false,
}) {
  return NadaSession(
    id: '${start.microsecondsSinceEpoch}',
    startedAt: start,
    endedAt: start.add(duration),
    duration: duration,
    mode: mode,
    goal: goal,
    completed: completed,
  );
}

void main() {
  group('controller', () {
    test('a finished session enters the ledger and the total', () async {
      final repository = MemoryRepository();
      final controller = NadaController(
        repository: repository,
        notifications: SilentNotifications(),
        widgets: const NoopWidgetService(),
      );
      await controller.init();

      controller.startSession();
      final started = controller.active!.startedAt;
      controller.finishSession(now: started.add(const Duration(minutes: 25)));

      expect(controller.stats.sessionCount, 1);
      expect(controller.stats.total, const Duration(minutes: 25));
      expect(controller.lastFinished, isNotNull);
      expect(controller.lastFinished!.completed, isFalse);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repository.data.sessions, hasLength(1));
      controller.dispose();
    });

    test('a goal session is capped at the goal when it completes', () async {
      final repository = MemoryRepository();
      final controller = NadaController(
        repository: repository,
        notifications: SilentNotifications(),
        widgets: const NoopWidgetService(),
      );
      await controller.init();
      controller.updateSettings(
        const NadaSettings(mode: NadaMode.goal, goalMinutes: 25),
      );

      controller.startSession();
      final started = controller.active!.startedAt;
      controller.finishSession(
        reachedGoal: true,
        now: started.add(const Duration(minutes: 40)),
      );

      expect(controller.stats.total, const Duration(minutes: 25));
      expect(controller.lastFinished!.completed, isTrue);
      expect(controller.lastFinished!.goal, const Duration(minutes: 25));
      expect(
        controller.lastFinished!.endedAt.difference(
          controller.lastFinished!.startedAt,
        ),
        const Duration(minutes: 25),
      );
      controller.dispose();
    });

    test('editing the selected quick time moves the goal with it', () async {
      final repository = MemoryRepository();
      final controller = NadaController(
        repository: repository,
        notifications: SilentNotifications(),
        widgets: const NoopWidgetService(),
      );
      await controller.init();
      controller.updateSettings(
        const NadaSettings(mode: NadaMode.goal, goalMinutes: 25),
      );

      controller.updateQuickMinute(0, 20);

      expect(controller.settings.quickMinutes, [20, 45, 90]);
      expect(controller.settings.goalMinutes, 20);
      controller.dispose();
    });

    test('editing another quick time leaves the selected goal alone', () async {
      final repository = MemoryRepository();
      final controller = NadaController(
        repository: repository,
        notifications: SilentNotifications(),
        widgets: const NoopWidgetService(),
      );
      await controller.init();
      controller.updateSettings(
        const NadaSettings(mode: NadaMode.goal, goalMinutes: 45),
      );

      controller.updateQuickMinute(0, 20);

      expect(controller.settings.quickMinutes, [20, 45, 90]);
      expect(controller.settings.goalMinutes, 45);
      controller.dispose();
    });

    test('quick times outside the valid range are ignored', () async {
      final repository = MemoryRepository();
      final controller = NadaController(
        repository: repository,
        notifications: SilentNotifications(),
        widgets: const NoopWidgetService(),
      );
      await controller.init();

      controller.updateQuickMinute(0, 0);
      controller.updateQuickMinute(1, 1000);

      expect(controller.settings.quickMinutes, [25, 45, 90]);
      controller.dispose();
    });

    test('a session shorter than three seconds is not recorded', () async {
      final repository = MemoryRepository();
      final controller = NadaController(
        repository: repository,
        notifications: SilentNotifications(),
        widgets: const NoopWidgetService(),
      );
      await controller.init();

      controller.startSession();
      controller.finishSession(
        now: controller.active!.startedAt.add(const Duration(seconds: 1)),
      );

      expect(controller.stats.sessionCount, 0);
      expect(controller.lastFinished, isNull);
      controller.dispose();
    });

    test('deleting a session updates the total', () async {
      final repository = MemoryRepository();
      final controller = NadaController(
        repository: repository,
        notifications: SilentNotifications(),
        widgets: const NoopWidgetService(),
      );
      await controller.init();

      controller.startSession();
      controller.finishSession(
        now: controller.active!.startedAt.add(const Duration(minutes: 10)),
      );
      final id = controller.sessions.single.id;
      controller.deleteSession(id);

      expect(controller.stats.sessionCount, 0);
      expect(controller.stats.total, Duration.zero);
      controller.dispose();
    });
  });

  group('settings', () {
    test('a v1 install migrates its presets once', () {
      final migrated = NadaStoreData.fromJson({
        'version': 1,
        'sessions': <Object?>[],
        'settings': {
          'quickMinutes': [15, 25, 45],
          'goalMinutes': 25,
          'mode': 'goal',
        },
      });

      expect(migrated.version, NadaStoreData.currentVersion);
      expect(migrated.settings.quickMinutes, [25, 45, 90]);
      expect(migrated.settings.goalMinutes, 45);
    });

    test('a v2 install keeps the old values if it chose them', () {
      final untouched = NadaStoreData.fromJson({
        'version': 2,
        'sessions': <Object?>[],
        'settings': {
          'quickMinutes': [15, 25, 45],
          'goalMinutes': 15,
          'mode': 'goal',
        },
      });

      expect(untouched.settings.quickMinutes, [15, 25, 45]);
      expect(untouched.settings.goalMinutes, 15);
    });

    test('the default presets are named pomodoro, jornada and maratón', () {
      const settings = NadaSettings();
      expect(settings.quickMinutes, [25, 45, 90]);
      expect(nadaPresetNames, ['pomodoro', 'jornada', 'maratón']);
    });
  });

  group('stats', () {
    test('totals today, week and streak', () {
      final now = DateTime(2026, 10, 23, 12);
      final sessions = [
        sessionAt(
          DateTime(2026, 10, 23, 9),
          duration: const Duration(minutes: 30),
        ),
        sessionAt(
          DateTime(2026, 10, 22, 9),
          duration: const Duration(minutes: 20),
        ),
        sessionAt(
          DateTime(2026, 10, 21, 9),
          duration: const Duration(minutes: 10),
        ),
        sessionAt(
          DateTime(2026, 10, 18, 9),
          duration: const Duration(hours: 1),
        ),
      ];
      final stats = NadaStats.fromSessions(sessions, now: now);

      expect(stats.total, const Duration(hours: 2));
      expect(stats.today, const Duration(minutes: 30));
      expect(stats.sessionCount, 4);
      expect(stats.streakDays, 3);
      expect(stats.longest, const Duration(hours: 1));
    });

    test('a streak survives a day that has not ended yet', () {
      final now = DateTime(2026, 10, 23, 8);
      final sessions = [
        sessionAt(DateTime(2026, 10, 22, 9)),
        sessionAt(DateTime(2026, 10, 21, 9)),
      ];
      expect(NadaStats.fromSessions(sessions, now: now).streakDays, 2);
    });

    test('a gap resets the streak', () {
      final now = DateTime(2026, 10, 23, 8);
      final sessions = [
        sessionAt(DateTime(2026, 10, 19, 9)),
        sessionAt(DateTime(2026, 10, 18, 9)),
      ];
      expect(NadaStats.fromSessions(sessions, now: now).streakDays, 0);
    });

    test('medals count 45-minute blocks, weekly and all-time', () {
      final now = DateTime(2026, 10, 23, 12);
      final sessions = [
        sessionAt(
          DateTime(2026, 10, 23, 9),
          duration: const Duration(minutes: 100),
        ),
        sessionAt(
          DateTime(2026, 10, 19, 9),
          duration: const Duration(minutes: 20),
        ),
        sessionAt(
          DateTime(2026, 10, 18, 9),
          duration: const Duration(minutes: 90),
        ),
      ];
      final stats = NadaStats.fromSessions(sessions, now: now);

      expect(stats.week, const Duration(minutes: 120));
      expect(stats.medalsThisWeek, 2);
      expect(stats.medalsTotal, 4);
      expect(stats.minutesToNextMedal, 15);
    });

    test('the medal week starts on Monday', () {
      final now = DateTime(2026, 10, 19, 9); // Monday
      final sessions = [
        sessionAt(
          DateTime(2026, 10, 18, 23),
          duration: const Duration(minutes: 60),
        ),
      ];
      final stats = NadaStats.fromSessions(sessions, now: now);

      expect(stats.week, Duration.zero);
      expect(stats.medalsThisWeek, 0);
      expect(stats.medalsTotal, 1);
    });
  });

  testWidgets('idle screen starts a session of nothing', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MemoryRepository();
    await tester.pumpWidget(
      NadaApp(
        repository: repository,
        notifications: SilentNotifications(),
        widgets: const NoopWidgetService(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('empezar a no hacer nada'), findsOneWidget);
    expect(find.text('nada!'), findsWidgets);
    expect(find.text('pomodoro'), findsOneWidget);
    expect(find.text('jornada'), findsOneWidget);
    expect(find.text('maratón'), findsOneWidget);
    expect(find.text('ninguna esta semana'), findsOneWidget);

    await tester.tap(find.text('empezar a no hacer nada'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('en curso'), findsNothing);
    expect(find.text('pausar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
