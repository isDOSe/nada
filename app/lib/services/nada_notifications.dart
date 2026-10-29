import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/nada_format.dart';
import '../core/nada_theme.dart';
import '../data/nada_models.dart';

/// What the controller needs from notifications. A test or a future iOS build
/// can implement this without touching the Android plugin.
abstract interface class SessionNotifications {
  bool get permissionGranted;

  Future<bool> ensurePermission();

  Future<void> refreshPermission();

  Future<void> showOngoing({
    required NadaMode mode,
    required Duration elapsed,
    Duration? goal,
    required DateTime startedAt,
    required bool notificationsEnabled,
  });

  Future<void> scheduleGoal({
    required DateTime endAt,
    required Duration goal,
    required bool notificationsEnabled,
    required bool soundEnabled,
  });

  Future<void> cancelSession();

  Future<void> cancelGoalAlert();

  Future<void> openSystemSettings();
}

/// The line under the notification title.
///
/// It only carries facts that do not change while the session runs: the goal
/// and the wall-clock end time. The live countdown belongs to Android's native
/// chronometer; baking "quedan 46 s" into the text would leave that number
/// frozen at whatever second the notification was last posted.
@visibleForTesting
String ongoingNotificationBody({
  required NadaMode mode,
  required Duration elapsed,
  Duration? goal,
  required DateTime startedAt,
  required DateTime now,
}) {
  if (mode == NadaMode.goal && goal != null) {
    final left = goal - elapsed;
    final remaining = left.isNegative ? Duration.zero : left;
    final endAt = now.add(remaining);
    return 'meta de ${compactDuration(goal)} · hasta las ${clockTime(endAt)}';
  }
  return 'sin hacer nada desde las ${clockTime(startedAt)}';
}

/// The persistent notification is deliberately native: Android renders the
/// chronometer itself, so it keeps ticking even when the Dart isolate is
/// frozen or killed. We never write a notification update every second.
class NadaNotifications implements SessionNotifications {
  NadaNotifications._();

  static final NadaNotifications instance = NadaNotifications._();

  static const int _ongoingId = 41;
  static const int _goalId = 42;
  static const String _ongoingChannel = 'nada_sesion';
  static const String _alertsChannel = 'nada_avisos_v2';
  static const String _silentAlertsChannel = 'nada_avisos_silencio';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _permissionGranted = false;
  bool _permissionAsked = false;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get permissionGranted => _permissionGranted;

  Future<void> init() async {
    if (!isSupported) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_nada'),
      );
      await _plugin.initialize(settings: settings);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _ongoingChannel,
          'sesión de nada',
          description: 'El tiempo que no le debes a nadie.',
          importance: Importance.low,
          playSound: false,
          showBadge: false,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _alertsChannel,
          'avisos de nada',
          description: 'Cuando una meta de nada se cumple.',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('nada_chime'),
          showBadge: false,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _silentAlertsChannel,
          'avisos de nada (silencio)',
          description: 'Cuando una meta de nada se cumple, sin sonido.',
          importance: Importance.low,
          playSound: false,
          showBadge: false,
        ),
      );
      _ready = true;
    } catch (error, stack) {
      _ready = false;
      debugPrint('NADA_NOTIF init failed: $error\n$stack');
    }
  }

  @override
  Future<bool> ensurePermission() async {
    if (!isSupported) return false;
    if (_permissionGranted) return true;

    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // The user may have granted the permission from system settings after
      // denying the first prompt. Check the real state before asking again.
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == true) {
        _permissionGranted = true;
      } else if (!_permissionAsked) {
        final granted = await android?.requestNotificationsPermission();
        _permissionAsked = true;
        _permissionGranted = granted ?? false;
      }
    } catch (_) {
      _permissionAsked = true;
    }

    if (!_ready) await init();
    return _permissionGranted;
  }

  @override
  Future<void> refreshPermission() async {
    if (!isSupported) return;
    if (!_ready) await init();
    if (!_ready) return;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled != null) _permissionGranted = enabled;
    } catch (_) {}
  }

  @override
  Future<void> showOngoing({
    required NadaMode mode,
    required Duration elapsed,
    Duration? goal,
    required DateTime startedAt,
    required bool notificationsEnabled,
  }) async {
    if (!isSupported || !notificationsEnabled) return;
    if (!_permissionGranted && _permissionAsked) return;
    if (!_ready) await init();
    if (!_ready) return;

    final now = DateTime.now();
    final isGoal = mode == NadaMode.goal && goal != null;
    final remaining = isGoal ? goal - elapsed : null;
    final when = isGoal
        ? now.add(remaining!.isNegative ? Duration.zero : remaining)
        : now.subtract(elapsed);

    final body = ongoingNotificationBody(
      mode: mode,
      elapsed: elapsed,
      goal: goal,
      startedAt: startedAt,
      now: now,
    );

    try {
      await _plugin.show(
        id: _ongoingId,
        title: 'nada!',
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _ongoingChannel,
            'sesión de nada',
            channelDescription: 'El tiempo que no le debes a nadie.',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            silent: true,
            showWhen: true,
            when: when.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: isGoal,
            category: AndroidNotificationCategory.stopwatch,
            visibility: NotificationVisibility.public,
            color: NadaColors.voidBlack,
          ),
        ),
      );
    } catch (error, stack) {
      // A denied permission must never interrupt the session.
      debugPrint('NADA_NOTIF show failed: $error\n$stack');
    }
  }

  /// Only scheduled when the app goes to the background, so a foreground
  /// session never gets a duplicate alert at the finish line.
  @override
  Future<void> scheduleGoal({
    required DateTime endAt,
    required Duration goal,
    required bool notificationsEnabled,
    required bool soundEnabled,
  }) async {
    if (!isSupported || !notificationsEnabled) return;
    if (!_ready) await init();
    if (!_ready) return;
    final body = '${compactDuration(goal)} de nada. ya está.';
    final channel = soundEnabled ? _alertsChannel : _silentAlertsChannel;
    try {
      await _plugin.zonedSchedule(
        id: _goalId,
        title: 'nada!',
        body: body,
        scheduledDate: tz.TZDateTime.from(endAt.toUtc(), tz.UTC),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            soundEnabled ? 'avisos de nada' : 'avisos de nada (silencio)',
            channelDescription: 'Cuando una meta de nada se cumple.',
            importance: soundEnabled
                ? Importance.defaultImportance
                : Importance.low,
            priority: soundEnabled ? Priority.defaultPriority : Priority.low,
            playSound: soundEnabled,
            sound: soundEnabled
                ? const RawResourceAndroidNotificationSound('nada_chime')
                : null,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Scheduling is a courtesy, not a requirement.
    }
  }

  @override
  Future<void> cancelSession() async {
    if (!isSupported) return;
    try {
      await _plugin.cancel(id: _ongoingId);
      await _plugin.cancel(id: _goalId);
    } catch (_) {}
  }

  @override
  Future<void> cancelGoalAlert() async {
    if (!isSupported) return;
    try {
      await _plugin.cancel(id: _goalId);
    } catch (_) {}
  }

  @override
  Future<void> openSystemSettings() async {
    if (!isSupported) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    } catch (_) {}
  }
}
