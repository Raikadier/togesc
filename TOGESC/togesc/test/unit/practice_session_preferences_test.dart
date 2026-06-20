import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/models/practice_session_preferences.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  group('PracticeSessionPreferences', () {
    test('SessionRoundGoal.fromRounds mapea valores conocidos', () {
      expect(SessionRoundGoal.fromRounds(0), SessionRoundGoal.unlimited);
      expect(SessionRoundGoal.fromRounds(5), SessionRoundGoal.five);
      expect(SessionRoundGoal.fromRounds(10), SessionRoundGoal.ten);
      expect(SessionRoundGoal.fromRounds(20), SessionRoundGoal.twenty);
      expect(SessionRoundGoal.fromRounds(99), SessionRoundGoal.unlimited);
    });

    test('persistencia en AppPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await SharedPreferences.getInstance();
      final prefs = AppPreferences(store);

      expect(prefs.practiceSessionPreferences.roundGoal,
          SessionRoundGoal.unlimited);
      expect(prefs.practiceSessionPreferences.autoAdvanceAfterResult, isFalse);

      await prefs.setPracticeSessionPreferences(
        const PracticeSessionPreferences(
          roundGoal: SessionRoundGoal.ten,
          autoAdvanceAfterResult: true,
        ),
      );

      expect(prefs.practiceSessionPreferences.roundGoal, SessionRoundGoal.ten);
      expect(prefs.practiceSessionPreferences.autoAdvanceAfterResult, isTrue);
      expect(prefs.practiceSessionPreferences.targetRounds, 10);
    });
  });
}
