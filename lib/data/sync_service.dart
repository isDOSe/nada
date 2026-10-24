import 'package:timezone/timezone.dart' as tz;

import 'nada_models.dart';

/// The app's only outbound dependency for sync.
///
/// Today it is a no-op: nothing leaves the device. When premium arrives,
/// implement this with Supabase (or PocketBase / Turso) and inject it in
/// `main.dart`. The controller already calls it on every ledger change, so no
/// UI or domain code has to change.
abstract interface class SyncService {
  /// Called after a local write. Implementations should be debounced and
  /// must never block the UI.
  Future<void> onLocalChange(NadaStoreData data);

  /// Called on launch by a future premium build to merge remote sessions.
  Future<NadaStoreData?> pull();
}

class NoopSyncService implements SyncService {
  const NoopSyncService();

  @override
  Future<void> onLocalChange(NadaStoreData data) async {}

  @override
  Future<NadaStoreData?> pull() async => null;
}

/// A helper a future Supabase adapter can use to turn a session into a row.
/// Kept here so the schema and the local model cannot drift apart.
Map<String, Object?> sessionToRow(NadaSession session, {String? userId}) => {
  'id': session.id,
  'user_id': userId,
  'started_at': session.startedAt.toUtc().toIso8601String(),
  'ended_at': session.endedAt.toUtc().toIso8601String(),
  'duration_ms': session.duration.inMilliseconds,
  'mode': session.mode.name,
  'goal_ms': session.goal?.inMilliseconds,
  'completed': session.completed,
};

/// Absolute UTC instant used by the notification scheduler.
tz.TZDateTime utcInstant(DateTime instant) =>
    tz.TZDateTime.from(instant.toUtc(), tz.UTC);
