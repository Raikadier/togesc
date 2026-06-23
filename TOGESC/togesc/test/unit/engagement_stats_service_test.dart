import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/services/engagement_stats_service.dart';

void main() {
  group('EngagementStatsService', () {
    test('computeStreakDays cuenta dias consecutivos', () {
      final now = DateTime(2026, 6, 22, 12);
      final history = [
        PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 5,
          correctRounds: 4,
          endedAt: now,
        ),
        PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 3,
          correctRounds: 2,
          endedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      expect(
        EngagementStatsService.computeStreakDays(history, now: now),
        2,
      );
    });

    test('computeModeMastery agrega por modo', () {
      final history = [
        PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 10,
          correctRounds: 8,
          endedAt: DateTime(2026, 1, 1),
        ),
        PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 5,
          correctRounds: 5,
          endedAt: DateTime(2026, 1, 2),
        ),
      ];

      final mastery = EngagementStatsService.computeModeMastery(history);
      final single = mastery.firstWhere((m) => m.mode == GameMode.singleNote);
      expect(single.sessionsCount, 2);
      expect(single.accuracyPercent, closeTo(86.67, 0.1));
    });

    test('xpFromSession usa 10 por acierto', () {
      expect(EngagementStatsService.xpFromSession(7), 70);
    });
  });
}
