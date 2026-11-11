import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/utils/session_summary.dart';

PracticeSessionLog _log(
  DateTime at, {
  int mode = 1,
  int rounds = 10,
  int correct = 5,
  PracticeKind kind = PracticeKind.game,
}) =>
    PracticeSessionLog(
      modeId: mode,
      kind: kind,
      roundsCompleted: rounds,
      correctRounds: correct,
      endedAt: at,
    );

void main() {
  final now = DateTime(2026, 11, 10, 18);

  group('sessionHeadline', () {
    test('las tres primeras sesiones son mediciones, sin valorar', () {
      expect(
        sessionHeadline(sessionNumber: 1, accuracyPercent: 0),
        'Primera medición hecha',
      );
      expect(
        sessionHeadline(sessionNumber: 2, accuracyPercent: 100),
        'Segunda medición hecha',
      );
      expect(
        sessionHeadline(sessionNumber: 3, accuracyPercent: 40),
        'Tercera medición hecha',
      );
      expect(isMeasuringSession(1), isTrue);
      expect(isMeasuringSession(3), isTrue);
    });

    test('desde la cuarta, o sin número, manda la medalla', () {
      expect(isMeasuringSession(4), isFalse);
      expect(isMeasuringSession(null), isFalse);
      expect(
        sessionHeadline(sessionNumber: 4, accuracyPercent: 80),
        SessionMedal.great.headline,
      );
      expect(
        sessionHeadline(sessionNumber: null, accuracyPercent: 30),
        SessionMedal.keepGoing.headline,
      );
    });
  });

  group('sessionDeltaLine', () {
    String? delta(double acc, double? prev) => sessionDeltaLine(
          accuracyPercent: acc,
          previousAccuracyPercent: prev,
        );

    test('sin sesión anterior no dice nada', () {
      expect(delta(50, null), isNull);
    });

    test('más, menos e igual, con el singular bien concordado', () {
      expect(delta(75, 70), '5 puntos más que la última vez.');
      expect(delta(51, 50), '1 punto más que la última vez.');
      expect(delta(40, 60), '20 puntos menos que la última vez.');
      expect(delta(50.4, 50), 'Igual que la última vez.');
    });
  });

  group('historial', () {
    test('previousSessionAccuracy: la más reciente del mismo modo', () {
      final history = [
        _log(now.subtract(const Duration(days: 1)), correct: 8),
        _log(now.subtract(const Duration(days: 3)), correct: 2),
        // Otro modo y Velocidad no cuentan.
        _log(now, mode: 2, correct: 10),
        _log(now, kind: PracticeKind.speed, correct: 10),
      ];
      expect(previousSessionAccuracy(history, modeId: 1), 80);
      expect(previousSessionAccuracy(history, modeId: 5), isNull);
      expect(previousSessionAccuracy(const [], modeId: 1), isNull);
    });

    test('lastAccuracyToday: solo sesiones de hoy', () {
      expect(lastAccuracyToday(const [], now: now), isNull);
      expect(
        lastAccuracyToday(
          [_log(now.subtract(const Duration(days: 1)))],
          now: now,
        ),
        isNull,
      );
      expect(
        lastAccuracyToday(
          [
            _log(DateTime(2026, 11, 10, 9), correct: 3),
            _log(DateTime(2026, 11, 10, 12), correct: 7),
          ],
          now: now,
        ),
        70,
      );
    });
  });

  group('nextSessionLine', () {
    test('lista las notas con «y» y resume a partir de la cuarta', () {
      expect(nextSessionLine(const []), 'Próxima sesión: notas nuevas.');
      expect(nextSessionLine(const ['Fa']), 'Próxima sesión: Fa.');
      expect(nextSessionLine(const ['Fa', 'La#']), 'Próxima sesión: Fa y La#.');
      expect(
        nextSessionLine(const ['Fa', 'La#', 'Si']),
        'Próxima sesión: Fa, La# y Si.',
      );
      expect(
        nextSessionLine(const ['Do', 'Re', 'Mi', 'Fa', 'Sol']),
        'Próxima sesión: Do, Re, Mi y 2 más.',
      );
    });
  });

  test('bestStreakLine solo desde 3 seguidas', () {
    expect(bestStreakLine(0), isNull);
    expect(bestStreakLine(2), isNull);
    expect(bestStreakLine(3), 'Tu mejor racha: 3 seguidas.');
  });
}
