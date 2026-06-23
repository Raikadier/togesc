import '../constants/game_constants.dart';
import '../models/engagement_stats.dart';
import '../models/practice_session_log.dart';

/// Calcula metricas de engagement desde historial y prefs.
abstract final class EngagementStatsService {
  static const int xpPerCorrectRound = 10;
  static const int xpMilestoneSize = 100;

  /// Dias consecutivos con al menos una sesion (fechas locales).
  static int computeStreakDays(
    List<PracticeSessionLog> history, {
    DateTime? now,
  }) {
    if (history.isEmpty) return 0;

    final clock = now ?? DateTime.now();
    final practiceDays = history
        .map((e) => _localDate(e.endedAt))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    var streak = 0;
    var expected = _localDate(clock);

    for (final day in practiceDays) {
      if (day == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (day.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  static DateTime _localDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static List<ModeMasteryStats> computeModeMastery(
    List<PracticeSessionLog> history,
  ) {
    final byMode = <int, _ModeAccumulator>{};

    for (final entry in history) {
      final acc = byMode.putIfAbsent(entry.modeId, _ModeAccumulator.new);
      acc.sessions++;
      acc.rounds += entry.roundsCompleted;
      acc.correct += entry.correctRounds;
    }

    return GameMode.values
        .where((m) => m != GameMode.exit && m != GameMode.speedTraining)
        .map((mode) {
          final acc = byMode[mode.id];
          return ModeMasteryStats(
            mode: mode,
            sessionsCount: acc?.sessions ?? 0,
            totalRounds: acc?.rounds ?? 0,
            correctRounds: acc?.correct ?? 0,
          );
        })
        .toList();
  }

  static int xpFromSession(int correctRounds) =>
      correctRounds * xpPerCorrectRound;

  static EngagementStats build({
    required List<PracticeSessionLog> history,
    required int totalXp,
    DateTime? now,
  }) {
    final milestoneRemainder = totalXp % xpMilestoneSize;
    return EngagementStats(
      currentStreakDays: computeStreakDays(history, now: now),
      totalXp: totalXp,
      xpTowardNextMilestone: milestoneRemainder,
      xpMilestoneSize: xpMilestoneSize,
      modeMastery: computeModeMastery(history),
    );
  }
}

class _ModeAccumulator {
  int sessions = 0;
  int rounds = 0;
  int correct = 0;
}
