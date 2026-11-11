import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import '../models/last_practice_session.dart';
import '../models/practice_session_log.dart';
import '../services/app_preferences.dart';
import '../services/engagement_stats_service.dart';
import '../utils/milestones.dart';
import 'app_preferences_provider.dart';

/// Hitos conseguidos (v2.2, lote D), del más antiguo al más reciente.
/// Se recalcula cuando cambia el historial: [SessionHistoryNotifier.record]
/// guarda los hitos antes de publicar el historial nuevo.
final milestoneLogProvider = Provider<List<Milestone>>((ref) {
  ref.watch(sessionHistoryProvider);
  return ref.watch(appPreferencesProvider).valueOrNull?.milestones ?? const [];
});

final sessionHistoryProvider =
    AsyncNotifierProvider<SessionHistoryNotifier, List<PracticeSessionLog>>(
      SessionHistoryNotifier.new,
    );

class SessionHistoryNotifier extends AsyncNotifier<List<PracticeSessionLog>> {
  @override
  Future<List<PracticeSessionLog>> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.sessionHistory;
  }

  Future<void> record({
    required GameMode mode,
    required PracticeKind kind,
    required int roundsCompleted,
    required int correctRounds,
    DateTime? endedAt,
    List<Milestone> sessionMilestones = const [],
  }) async {
    if (roundsCompleted <= 0) return;

    final prefs = await ref.read(appPreferencesProvider.future);
    final entry = PracticeSessionLog(
      modeId: mode.id,
      kind: kind,
      roundsCompleted: roundsCompleted,
      correctRounds: correctRounds.clamp(0, roundsCompleted),
      endedAt: endedAt ?? DateTime.now(),
    );
    final prior = prefs.sessionHistory;
    final next = await prefs.appendSessionLog(entry);
    await _updateRecords(prefs, entry, prior, next, sessionMilestones);
    final xp = EngagementStatsService.xpFromSession(correctRounds);
    await prefs.addXp(xp);
    state = AsyncData(next);
  }

  /// Guarda la mejor precisión del modo y la mejor racha de días, y añade los
  /// hitos de la sesión más el de racha récord si lo hay.
  Future<void> _updateRecords(
    AppPreferences prefs,
    PracticeSessionLog entry,
    List<PracticeSessionLog> prior,
    List<PracticeSessionLog> next,
    List<Milestone> sessionMilestones,
  ) async {
    if (entry.kind == PracticeKind.game) {
      final best = bestAccuracyOfMode(
        prior,
        entry.modeId,
        stored: prefs.bestSessionAccuracy(entry.modeId),
      );
      if (best == null || entry.accuracyPercent > best) {
        await prefs.setBestSessionAccuracy(entry.modeId, entry.accuracyPercent);
      }
    }
    final previousBestStreak = math.max(
      prefs.bestStreakDays,
      longestStreakDays(prior),
    );
    final streak = EngagementStatsService.computeStreakDays(
      next,
      now: entry.endedAt,
    );
    final streakRecord = streakRecordMilestone(
      streakDays: streak,
      previousBest: previousBestStreak,
      now: entry.endedAt,
    );
    if (streak > prefs.bestStreakDays) await prefs.setBestStreakDays(streak);
    final earned = [...sessionMilestones, ?streakRecord];
    await prefs.addMilestones(earned);
  }

  Future<void> clear() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.clearSessionHistory();
    state = const AsyncData([]);
  }
}
