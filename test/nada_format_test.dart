import 'package:flutter_test/flutter_test.dart';
import 'package:nada/core/nada_format.dart';

void main() {
  group('stopwatch', () {
    test('formats under an hour as mm:ss', () {
      expect(stopwatch(const Duration(seconds: 42)), '00:42');
      expect(stopwatch(const Duration(minutes: 18, seconds: 7)), '18:07');
    });

    test('formats an hour and beyond as h:mm:ss', () {
      expect(
        stopwatch(const Duration(hours: 2, minutes: 8, seconds: 3)),
        '2:08:03',
      );
    });
  });

  group('compactDuration', () {
    test('uses human units', () {
      expect(compactDuration(const Duration(seconds: 42)), '42 s');
      expect(compactDuration(const Duration(minutes: 48)), '48 min');
      expect(
        compactDuration(const Duration(hours: 3, minutes: 12)),
        '3 h 12 min',
      );
      expect(compactDuration(const Duration(hours: 3)), '3 h');
    });

    test('can render zero as a dash', () {
      expect(compactDuration(Duration.zero, zeroAsDash: true), '—');
    });
  });

  group('spokenDuration', () {
    test('speaks in singular and plural', () {
      expect(spokenDuration(const Duration(seconds: 1)), '1 segundo');
      expect(spokenDuration(const Duration(minutes: 1)), '1 minuto');
      expect(
        spokenDuration(const Duration(minutes: 18, seconds: 42)),
        '18 minutos y 42 segundos',
      );
      expect(
        spokenDuration(const Duration(hours: 1, minutes: 5)),
        '1 hora y 5 minutos',
      );
    });
  });

  group('labels', () {
    test('streak label stays honest', () {
      expect(streakLabel(0), 'sin racha');
      expect(streakLabel(1), 'racha de 1 día');
      expect(streakLabel(4), 'racha de 4 días');
    });

    test('session count label', () {
      expect(sessionCountLabel(0), 'ninguna sesión');
      expect(sessionCountLabel(1), '1 sesión');
      expect(sessionCountLabel(14), '14 sesiones');
    });
  });
}
