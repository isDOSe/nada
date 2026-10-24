import 'dart:math';

/// How a session of nothing is measured.
enum NadaMode {
  /// Counts up forever. The purest form.
  free,

  /// Counts down to an intention. The Pomodoro disguise.
  goal;

  static NadaMode fromName(String? value) {
    return NadaMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => NadaMode.free,
    );
  }
}

/// A finished stretch of nothing.
class NadaSession {
  const NadaSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.mode,
    this.goal,
    this.completed = false,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final NadaMode mode;
  final Duration? goal;

  /// True when a goal session reached its goal.
  final bool completed;

  bool get reachedGoal => completed;

  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'endedAt': endedAt.millisecondsSinceEpoch,
    'durationMs': duration.inMilliseconds,
    'mode': mode.name,
    'goalMs': goal?.inMilliseconds,
    'completed': completed,
  };

  static NadaSession fromJson(Map<String, Object?> json) {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      (json['startedAt'] as num?)?.toInt() ?? 0,
    );
    return NadaSession(
      id: json['id'] as String? ?? newId(startedAt),
      startedAt: startedAt,
      endedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['endedAt'] as num?)?.toInt() ?? startedAt.millisecondsSinceEpoch,
      ),
      duration: Duration(
        milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0,
      ),
      mode: NadaMode.fromName(json['mode'] as String?),
      goal: json['goalMs'] == null
          ? null
          : Duration(milliseconds: (json['goalMs'] as num).toInt()),
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// The session currently in progress. Persisted so a process death does not
/// erase the time you spent doing nothing.
class ActiveSession {
  const ActiveSession({
    required this.startedAt,
    required this.lastResumedAt,
    required this.accumulated,
    required this.mode,
    required this.running,
    this.goal,
  });

  final DateTime startedAt;
  final DateTime lastResumedAt;
  final Duration accumulated;
  final NadaMode mode;
  final Duration? goal;
  final bool running;

  Duration elapsedAt(DateTime now) {
    if (!running) return accumulated;
    final live = now.difference(lastResumedAt);
    return accumulated + (live.isNegative ? Duration.zero : live);
  }

  Duration remainingAt(DateTime now) {
    final target = goal;
    if (target == null) return Duration.zero;
    final left = target - elapsedAt(now);
    return left.isNegative ? Duration.zero : left;
  }

  ActiveSession paused(DateTime now) => ActiveSession(
    startedAt: startedAt,
    lastResumedAt: now,
    accumulated: elapsedAt(now),
    mode: mode,
    goal: goal,
    running: false,
  );

  ActiveSession resumed(DateTime now) => ActiveSession(
    startedAt: startedAt,
    lastResumedAt: now,
    accumulated: accumulated,
    mode: mode,
    goal: goal,
    running: true,
  );

  Map<String, Object?> toJson() => {
    'startedAt': startedAt.millisecondsSinceEpoch,
    'lastResumedAt': lastResumedAt.millisecondsSinceEpoch,
    'accumulatedMs': accumulated.inMilliseconds,
    'mode': mode.name,
    'goalMs': goal?.inMilliseconds,
    'running': running,
  };

  static ActiveSession? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final startedAtMs = (json['startedAt'] as num?)?.toInt();
    if (startedAtMs == null) return null;
    return ActiveSession(
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
      lastResumedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['lastResumedAt'] as num?)?.toInt() ?? startedAtMs,
      ),
      accumulated: Duration(
        milliseconds: (json['accumulatedMs'] as num?)?.toInt() ?? 0,
      ),
      mode: NadaMode.fromName(json['mode'] as String?),
      goal: json['goalMs'] == null
          ? null
          : Duration(milliseconds: (json['goalMs'] as num).toInt()),
      running: json['running'] as bool? ?? false,
    );
  }
}

class NadaSettings {
  const NadaSettings({
    this.mode = NadaMode.free,
    this.goalMinutes = 25,
    this.quickMinutes = const [15, 25, 45],
    this.notifications = true,
  });

  final NadaMode mode;
  final int goalMinutes;

  /// The three editable durations shown on the home screen.
  final List<int> quickMinutes;
  final bool notifications;

  Duration get goal => Duration(minutes: goalMinutes);

  NadaSettings copyWith({
    NadaMode? mode,
    int? goalMinutes,
    List<int>? quickMinutes,
    bool? notifications,
  }) => NadaSettings(
    mode: mode ?? this.mode,
    goalMinutes: goalMinutes ?? this.goalMinutes,
    quickMinutes: quickMinutes ?? this.quickMinutes,
    notifications: notifications ?? this.notifications,
  );

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'goalMinutes': goalMinutes,
    'quickMinutes': quickMinutes,
    'notifications': notifications,
  };

  static NadaSettings fromJson(Map<String, Object?>? json) {
    if (json == null) return const NadaSettings();

    final rawQuick = json['quickMinutes'];
    final quick = <int>[];
    if (rawQuick is List) {
      for (final value in rawQuick) {
        if (value is num) {
          final minutes = value.toInt();
          if (minutes >= 1 && minutes <= 999) quick.add(minutes);
        }
      }
    }

    return NadaSettings(
      mode: NadaMode.fromName(json['mode'] as String?),
      goalMinutes: (json['goalMinutes'] as num?)?.toInt() ?? 25,
      quickMinutes: quick.length == 3 ? quick : const [15, 25, 45],
      notifications: json['notifications'] as bool? ?? true,
    );
  }
}

/// Everything the app knows. One small JSON document.
class NadaStoreData {
  const NadaStoreData({
    this.sessions = const [],
    this.active,
    this.settings = const NadaSettings(),
    this.version = 1,
  });

  final List<NadaSession> sessions;
  final ActiveSession? active;
  final NadaSettings settings;
  final int version;

  NadaStoreData copyWith({
    List<NadaSession>? sessions,
    ActiveSession? active,
    bool clearActive = false,
    NadaSettings? settings,
  }) => NadaStoreData(
    sessions: sessions ?? this.sessions,
    active: clearActive ? null : (active ?? this.active),
    settings: settings ?? this.settings,
    version: version,
  );

  Map<String, Object?> toJson() => {
    'version': version,
    'sessions': sessions.map((session) => session.toJson()).toList(),
    'active': active?.toJson(),
    'settings': settings.toJson(),
  };

  static NadaStoreData fromJson(Map<String, Object?> json) {
    final rawSessions = json['sessions'];
    final sessions = <NadaSession>[];
    if (rawSessions is List) {
      for (final raw in rawSessions) {
        if (raw is Map) {
          sessions.add(NadaSession.fromJson(raw.cast<String, Object?>()));
        }
      }
    }
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final rawActive = json['active'];
    return NadaStoreData(
      version: (json['version'] as num?)?.toInt() ?? 1,
      sessions: sessions,
      active: rawActive is Map
          ? ActiveSession.fromJson(rawActive.cast<String, Object?>())
          : null,
      settings: NadaSettings.fromJson(
        (json['settings'] as Map?)?.cast<String, Object?>(),
      ),
    );
  }
}

/// Small ledger numbers derived from the finished sessions.
class NadaStats {
  const NadaStats({
    required this.total,
    required this.today,
    required this.week,
    required this.sessionCount,
    required this.streakDays,
    required this.longest,
    required this.average,
  });

  final Duration total;
  final Duration today;
  final Duration week;
  final int sessionCount;
  final int streakDays;
  final Duration longest;
  final Duration average;

  static const empty = NadaStats(
    total: Duration.zero,
    today: Duration.zero,
    week: Duration.zero,
    sessionCount: 0,
    streakDays: 0,
    longest: Duration.zero,
    average: Duration.zero,
  );

  static NadaStats fromSessions(List<NadaSession> sessions, {DateTime? now}) {
    if (sessions.isEmpty) return empty;
    final current = now ?? DateTime.now();
    final todayStart = DateTime(current.year, current.month, current.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));

    var total = Duration.zero;
    var today = Duration.zero;
    var week = Duration.zero;
    var longest = Duration.zero;
    final days = <String>{};

    for (final session in sessions) {
      total += session.duration;
      if (session.duration > longest) longest = session.duration;
      final day = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      if (day == todayStart) today += session.duration;
      if (!day.isBefore(weekStart)) week += session.duration;
      days.add(_dayKey(day));
    }

    return NadaStats(
      total: total,
      today: today,
      week: week,
      sessionCount: sessions.length,
      streakDays: _streak(days, todayStart),
      longest: longest,
      average: Duration(milliseconds: total.inMilliseconds ~/ sessions.length),
    );
  }

  static String _dayKey(DateTime day) =>
      '${day.year}-${twoDigits(day.month)}-${twoDigits(day.day)}';

  static String twoDigits(int value) => value.toString().padLeft(2, '0');

  static int _streak(Set<String> days, DateTime todayStart) {
    if (days.isEmpty) return 0;
    var cursor = todayStart;
    if (!days.contains(_dayKey(cursor))) {
      // A streak survives until today ends; start counting from yesterday.
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

String newId(DateTime at) {
  final random = Random().nextInt(1 << 20).toRadixString(36);
  return '${at.microsecondsSinceEpoch.toRadixString(36)}-$random';
}
