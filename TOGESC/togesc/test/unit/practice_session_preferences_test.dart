import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/models/practice_session_preferences.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  group('PracticeSessionPreferences', () {
    test('SessionRoundGoal.fromRounds mapea valores conocidos', () {
      expect(SessionRoundGoal.fromRounds(null), SessionRoundGoal.unlimited);
      expect(SessionRoundGoal.fromRounds(0), SessionRoundGoal.unlimited);
      expect(SessionRoundGoal.fromRounds(5), SessionRoundGoal.five);
      expect(SessionRoundGoal.fromRounds(10), SessionRoundGoal.ten);
      expect(SessionRoundGoal.fromRounds(12), SessionRoundGoal.twelve);
      expect(SessionRoundGoal.fromRounds(20), SessionRoundGoal.twenty);
      expect(SessionRoundGoal.fromRounds(99), SessionRoundGoal.unlimited);
    });

    test('defaults v2: 12 rondas y avance automatico (D2, D3)', () {
      const prefs = PracticeSessionPreferences();
      expect(prefs.roundGoal, SessionRoundGoal.twelve);
      expect(prefs.targetRounds, 12);
      expect(prefs.autoAdvanceAfterResult, isTrue);
      expect(resultAutoAdvanceDelay, const Duration(milliseconds: 2200));
    });

    test('duracion estimada = rondas x 30 s, nula sin limite', () {
      expect(estimatedSecondsPerRound, 30);
      expect(
        SessionRoundGoal.twelve.estimatedDuration,
        const Duration(minutes: 6),
      );
      expect(SessionRoundGoal.twelve.estimatedMinutes, 6);
      expect(SessionRoundGoal.five.estimatedMinutes, 3); // 150 s -> techo 3
      expect(SessionRoundGoal.unlimited.estimatedDuration, isNull);
      expect(SessionRoundGoal.unlimited.estimatedMinutes, isNull);
      expect(const PracticeSessionPreferences().estimatedMinutes, 6);
      expect(estimateSessionMinutes(0), isNull);
    });

    test('persistencia en AppPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await SharedPreferences.getInstance();
      final prefs = AppPreferences(store);

      expect(
        prefs.practiceSessionPreferences.roundGoal,
        SessionRoundGoal.twelve,
      );
      expect(prefs.practiceSessionPreferences.autoAdvanceAfterResult, isTrue);

      await prefs.setPracticeSessionPreferences(
        const PracticeSessionPreferences(
          roundGoal: SessionRoundGoal.ten,
          autoAdvanceAfterResult: false,
        ),
      );

      expect(prefs.practiceSessionPreferences.roundGoal, SessionRoundGoal.ten);
      expect(prefs.practiceSessionPreferences.autoAdvanceAfterResult, isFalse);
      expect(prefs.practiceSessionPreferences.targetRounds, 10);
    });

    test('sin limite elegido tras v2 se conserva', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      await prefs.setPracticeSessionPreferences(
        const PracticeSessionPreferences(roundGoal: SessionRoundGoal.unlimited),
      );
      expect(
        prefs.practiceSessionPreferences.roundGoal,
        SessionRoundGoal.unlimited,
      );
    });

    test('migracion: legacy con defaults antiguos recibe defaults v2',
        () async {
      SharedPreferences.setMockInitialValues({
        sessionRoundGoalKey: 0,
        autoAdvanceAfterResultKey: false,
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(
        prefs.practiceSessionPreferences.roundGoal,
        SessionRoundGoal.twelve,
      );
      expect(prefs.practiceSessionPreferences.autoAdvanceAfterResult, isTrue);
    });

    test('migracion: legacy elegido por el usuario se conserva', () async {
      SharedPreferences.setMockInitialValues({
        sessionRoundGoalKey: 20,
        autoAdvanceAfterResultKey: true,
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(
        prefs.practiceSessionPreferences.roundGoal,
        SessionRoundGoal.twenty,
      );
      expect(prefs.practiceSessionPreferences.autoAdvanceAfterResult, isTrue);
    });

    test('migracion: el valor v2 manda sobre el legacy', () async {
      SharedPreferences.setMockInitialValues({
        sessionRoundGoalKey: 20,
        sessionRoundGoalV2Key: 5,
        autoAdvanceAfterResultKey: true,
        autoAdvanceAfterResultV2Key: false,
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(prefs.practiceSessionPreferences.roundGoal, SessionRoundGoal.five);
      expect(prefs.practiceSessionPreferences.autoAdvanceAfterResult, isFalse);
    });
  });

  group('migrateLegacyPreference', () {
    test('aplica la regla v2 > legacy explicito > default nuevo', () {
      expect(
        migrateLegacyPreference<int>(
          v2Value: null,
          legacyValue: null,
          legacyDefault: 0,
          newDefault: 12,
        ),
        12,
      );
      expect(
        migrateLegacyPreference<int>(
          v2Value: null,
          legacyValue: 0,
          legacyDefault: 0,
          newDefault: 12,
        ),
        12,
      );
      expect(
        migrateLegacyPreference<int>(
          v2Value: null,
          legacyValue: 5,
          legacyDefault: 0,
          newDefault: 12,
        ),
        5,
      );
      expect(
        migrateLegacyPreference<int>(
          v2Value: 0,
          legacyValue: 5,
          legacyDefault: 0,
          newDefault: 12,
        ),
        0,
      );
    });
  });
}
