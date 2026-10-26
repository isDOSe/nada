import 'package:flutter_test/flutter_test.dart';
import 'package:nada/data/nada_models.dart';
import 'package:nada/services/nada_notifications.dart';

void main() {
  final startedAt = DateTime(2026, 10, 26, 14, 5);
  const goal = Duration(minutes: 1);
  final at14s = startedAt.add(const Duration(seconds: 14));
  final at50s = startedAt.add(const Duration(seconds: 50));

  String goalBodyAt(DateTime now) => ongoingNotificationBody(
    mode: NadaMode.goal,
    elapsed: now.difference(startedAt),
    goal: goal,
    startedAt: startedAt,
    now: now,
  );

  group('ongoing notification body', () {
    test('goal mode never freezes the remaining seconds', () {
      // 14 s into a one-minute goal there are 46 s left. That number used to be
      // baked into the body and stayed there for the rest of the session.
      expect(goalBodyAt(at14s), 'meta de 1 min · hasta las 14:06');
      expect(goalBodyAt(at50s), goalBodyAt(at14s));
    });

    test('free mode pins the start time', () {
      expect(
        ongoingNotificationBody(
          mode: NadaMode.free,
          elapsed: const Duration(seconds: 14),
          startedAt: startedAt,
          now: at14s,
        ),
        'sin hacer nada desde las 14:05',
      );
    });
  });
}
