import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/nada_models.dart';
import '../data/session_repository.dart';
import '../data/sync_service.dart';
import '../services/nada_notifications.dart';
import '../services/nada_sound.dart';
import '../services/nada_widget_service.dart';

/// The single brain of nada!
///
/// The ticking second lives in [elapsed] (a [ValueNotifier]) so the hero clock
/// can repaint alone. Everything else — sessions, stats, settings — only
/// notifies on real state changes.
class NadaController extends ChangeNotifier {
  NadaController({
    required SessionRepository repository,
    SyncService sync = const NoopSyncService(),
    SessionNotifications? notifications,
    WidgetService? widgets,
    EndSound? sound,
  }) : _repository = repository,
       _sync = sync,
       _notifications = notifications ?? NadaNotifications.instance,
       _widgets = widgets ?? AndroidWidgetService(),
       _sound = sound ?? AndroidEndSound();

  final SessionRepository _repository;
  final SyncService _sync;
  final SessionNotifications _notifications;
  final WidgetService _widgets;
  final EndSound _sound;

  List<NadaSession> _sessions = const [];
  ActiveSession? _active;
  NadaSettings _settings = const NadaSettings();
  NadaStats _stats = NadaStats.empty;
  NadaSession? _lastFinished;
  bool _ready = false;
  Timer? _ticker;
  Future<void> _writeChain = Future.value();

  /// Repaints once per second, and only the clock listens.
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);

  bool get ready => _ready;
  bool get hasActiveSession => _active != null;
  bool get isRunning => _active?.running ?? false;
  bool get isPaused => _active != null && !_active!.running;
  bool get isGoalMode =>
      _active?.mode == NadaMode.goal && _active?.goal != null;
  ActiveSession? get active => _active;
  NadaSession? get lastFinished => _lastFinished;
  NadaSettings get settings => _settings;
  NadaStats get stats => _stats;
  List<NadaSession> get sessions => _sessions;
  Duration? get activeGoal => _active?.goal;
  DateTime? get activeStartedAt => _active?.startedAt;

  Future<void> init() async {
    final data = await _repository.load();
    await _notifications.refreshPermission();
    _sessions = List.unmodifiable(
      [...data.sessions]..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
    );
    _settings = data.settings;
    _stats = NadaStats.fromSessions(_sessions);
    _active = data.active;
    _ready = true;

    final current = _active;
    if (current != null) {
      final now = DateTime.now();
      final currentElapsed = current.elapsedAt(now);
      elapsed.value = currentElapsed;

      if (current.running &&
          current.goal != null &&
          currentElapsed >= current.goal!) {
        // The goal was reached while the app was away. Close it at its own
        // finish line, not at the arbitrary time you came back.
        finishSession(reachedGoal: true, now: now, playSound: false);
      } else {
        _syncTicker();
        if (current.running) {
          unawaited(
            _notifications.showOngoing(
              mode: current.mode,
              elapsed: currentElapsed,
              goal: current.goal,
              startedAt: current.startedAt,
              notificationsEnabled: _settings.notifications,
            ),
          );
        }
      }
    }

    notifyListeners();
    _syncWidgets();
    unawaited(
      _sync.pull().then((remote) {
        if (remote != null) {
          // Premium builds merge the remote ledger here.
        }
      }),
    );
  }

  void startSession() {
    if (_active != null) return;
    final now = DateTime.now();
    final mode = _settings.mode;
    _active = ActiveSession(
      startedAt: now,
      lastResumedAt: now,
      accumulated: Duration.zero,
      mode: mode,
      goal: mode == NadaMode.goal ? _settings.goal : null,
      running: true,
    );
    _lastFinished = null;
    elapsed.value = Duration.zero;
    _syncTicker();
    _persist();
    _notify();
    _notifySystem();
  }

  void pauseSession() {
    final current = _active;
    if (current == null || !current.running) return;
    final now = DateTime.now();
    final paused = current.paused(now);
    _active = paused;
    elapsed.value = paused.accumulated;
    _syncTicker();
    _persist();
    unawaited(_notifications.cancelSession());
    _notify();
  }

  void resumeSession() {
    final current = _active;
    if (current == null || current.running) return;
    final now = DateTime.now();
    final resumed = current.resumed(now);
    _active = resumed;
    _syncTicker();
    _persist();
    _notify();
    _notifySystem();
  }

  void finishSession({
    bool reachedGoal = false,
    DateTime? now,
    bool playSound = true,
  }) {
    final current = _active;
    if (current == null) return;
    final endedAt = now ?? DateTime.now();
    final target = current.goal;
    final measured = current.elapsedAt(endedAt);
    final completed = reachedGoal || (target != null && measured >= target);
    var duration = measured;
    var effectiveEnd = endedAt;

    if (completed && target != null) {
      // If the goal expired while the app was away, record the moment it was
      // actually reached, not the moment you came back to look at it.
      final overshoot = measured - target;
      if (overshoot > Duration.zero) {
        effectiveEnd = endedAt.subtract(overshoot);
      }
      duration = target;
    }

    final session = duration < const Duration(seconds: 3)
        ? null
        : NadaSession(
            id: newId(current.startedAt),
            startedAt: current.startedAt,
            endedAt: effectiveEnd,
            duration: duration,
            mode: current.mode,
            goal: target,
            completed: completed,
          );

    _active = null;
    _ticker?.cancel();
    _ticker = null;
    elapsed.value = Duration.zero;

    if (session != null) {
      _sessions = List.unmodifiable([session, ..._sessions]);
      _stats = NadaStats.fromSessions(_sessions);
      _lastFinished = session;
    } else {
      _lastFinished = null;
    }

    _persist();
    unawaited(_notifications.cancelSession());
    _notify();
    _syncWidgets();
    if (session != null && playSound && _settings.soundEnabled) {
      unawaited(_sound.play());
    }
  }

  Future<void> previewEndSound() => _sound.play();

  void dismissSummary() {
    _lastFinished = null;
    _notify();
  }

  void deleteSession(String id) {
    final next = _sessions.where((session) => session.id != id).toList();
    if (next.length == _sessions.length) return;
    _sessions = List.unmodifiable(next);
    _stats = NadaStats.fromSessions(_sessions);
    _persist();
    _notify();
    _syncWidgets();
  }

  void updateSettings(NadaSettings next) {
    final notificationsChanged = next.notifications != _settings.notifications;
    final widgetThemeChanged = next.widgetTheme != _settings.widgetTheme;
    _settings = next;
    _persist();
    if (notificationsChanged && !next.notifications) {
      unawaited(_notifications.cancelSession());
    } else if (notificationsChanged && next.notifications) {
      unawaited(_notifications.ensurePermission());
      _notifySystem();
    }
    _notify();
    if (widgetThemeChanged) _syncWidgets();
  }

  Future<bool> requestWidgetPin() => _widgets.requestPin();

  void _syncWidgets() {
    unawaited(_widgets.update(stats: _stats, theme: _settings.widgetTheme));
  }

  /// Edit one of the three home presets.
  ///
  /// If that preset is the currently selected goal, the goal follows the edit
  /// so the home does not lose its selection.
  void updateQuickMinute(int index, int minutes) {
    if (index < 0 || index >= _settings.quickMinutes.length) return;
    if (minutes < 1 || minutes > 999) return;
    final previous = _settings.quickMinutes[index];
    if (previous == minutes) return;

    final quick = [..._settings.quickMinutes]..[index] = minutes;
    var goal = _settings.goalMinutes;
    if (_settings.mode == NadaMode.goal && goal == previous) {
      goal = minutes;
    }

    _settings = _settings.copyWith(quickMinutes: quick, goalMinutes: goal);
    _persist();
    _notify();
  }

  /// Called when the app goes to the background. The chronometer keeps
  /// counting natively, and a goal notification is scheduled in case the
  /// process never comes back.
  void handleAppPaused() {
    final current = _active;
    if (current == null || !current.running) {
      _persist();
      return;
    }
    final now = DateTime.now();
    final value = current.elapsedAt(now);
    unawaited(
      _notifications.showOngoing(
        mode: current.mode,
        elapsed: value,
        goal: current.goal,
        startedAt: current.startedAt,
        notificationsEnabled: _settings.notifications,
      ),
    );
    final goal = current.goal;
    if (goal != null) {
      final remaining = goal - value;
      if (remaining > Duration.zero) {
        unawaited(
          _notifications.scheduleGoal(
            endAt: now.add(remaining),
            goal: goal,
            notificationsEnabled: _settings.notifications,
            soundEnabled: _settings.soundEnabled,
          ),
        );
      }
    }
    _persist();
  }

  /// Called on return. The in-app ticker catches up with wall-clock time and
  /// closes any goal that expired while we were away.
  void handleAppResumed() {
    final current = _active;
    if (current == null) return;
    // The in-app ticker is awake again, so the background alert is redundant.
    unawaited(_notifications.cancelGoalAlert());
    final now = DateTime.now();
    final value = current.elapsedAt(now);

    if (current.running && current.goal != null && value >= current.goal!) {
      finishSession(reachedGoal: true, now: now, playSound: false);
      return;
    }

    elapsed.value = value;
    _syncTicker();
    _notifySystem();
  }

  Future<bool> requestNotificationPermission() =>
      _notifications.ensurePermission();

  Future<void> refreshNotificationPermission() =>
      _notifications.refreshPermission();

  Future<void> openNotificationSettings() =>
      _notifications.openSystemSettings();

  bool get notificationsGranted => _notifications.permissionGranted;

  void _syncTicker() {
    final shouldTick = _active?.running ?? false;
    if (!shouldTick) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final current = _active;
    if (current == null || !current.running) return;
    final now = DateTime.now();
    final value = current.elapsedAt(now);
    elapsed.value = value;

    final goal = current.goal;
    if (goal != null && value >= goal) {
      finishSession(reachedGoal: true, now: now);
    }
  }

  void _notifySystem() {
    final current = _active;
    if (current == null || !current.running) return;
    if (!_settings.notifications) return;
    unawaited(
      _notifications.ensurePermission().then((granted) {
        if (!granted || _active == null) return;
        final now = DateTime.now();
        unawaited(
          _notifications.showOngoing(
            mode: _active!.mode,
            elapsed: _active!.elapsedAt(now),
            goal: _active!.goal,
            startedAt: _active!.startedAt,
            notificationsEnabled: _settings.notifications,
          ),
        );
      }),
    );
  }

  void _persist() {
    final snapshot = NadaStoreData(
      sessions: _sessions,
      active: _active,
      settings: _settings,
    );
    _writeChain = _writeChain
        .then((_) => _repository.save(snapshot))
        .catchError((Object _) {});
    unawaited(_sync.onLocalChange(snapshot));
  }

  void _notify() {
    if (!_ready) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    elapsed.dispose();
    super.dispose();
  }
}
