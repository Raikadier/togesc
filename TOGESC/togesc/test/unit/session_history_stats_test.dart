import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/utils/session_history_stats.dart';

void main() {
  test('buildDailyPracticeSummaries agrega rondas por dia', () {
    final now = DateTime(2026, 6, 21, 18);
    final history = [
      PracticeSessionLog(
        modeId: 0,
        kind: PracticeKind.game,
        roundsCompleted: 5,
        correctRounds: 4,
        endedAt: DateTime(2026, 6, 21, 10),
      ),
      PracticeSessionLog(
        modeId: 0,
        kind: PracticeKind.game,
        roundsCompleted: 3,
        correctRounds: 2,
        endedAt: DateTime(2026, 6, 20, 12),
      ),
    ];

    final summaries = buildDailyPracticeSummaries(
      history,
      now: now,
    );

    expect(summaries, hasLength(7));
    expect(summaries.last.rounds, 5);
    expect(summaries.last.correct, 4);
    expect(summaries.last.accuracyPercent, 80);
    expect(summaries[5].rounds, 3);
    expect(summaries.first.rounds, 0);
  });

  test('filterHistoryByPeriod respeta 7 y 30 dias', () {
    final now = DateTime(2026, 6, 21, 18);
    final history = [
      PracticeSessionLog(
        modeId: 0,
        kind: PracticeKind.game,
        roundsCompleted: 1,
        correctRounds: 1,
        endedAt: DateTime(2026, 6, 21, 10),
      ),
      PracticeSessionLog(
        modeId: 0,
        kind: PracticeKind.game,
        roundsCompleted: 1,
        correctRounds: 0,
        endedAt: DateTime(2026, 5, 1, 10),
      ),
    ];

    final week = filterHistoryByPeriod(
      history,
      StatsPeriod.days7,
      now: now,
    );
    expect(week, hasLength(1));

    final month = filterHistoryByPeriod(
      history,
      StatsPeriod.days30,
      now: now,
    );
    expect(month, hasLength(1));

    final all = filterHistoryByPeriod(
      history,
      StatsPeriod.all,
      now: now,
    );
    expect(all, hasLength(2));
  });

  test('buildPracticeSummariesForPeriod usa 30 dias', () {
    final now = DateTime(2026, 6, 21, 18);
    final summaries = buildPracticeSummariesForPeriod(
      const [],
      period: StatsPeriod.days30,
      now: now,
    );
    expect(summaries, hasLength(30));
  });
}
