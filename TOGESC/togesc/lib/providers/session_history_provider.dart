import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import '../models/last_practice_session.dart';
import '../models/practice_session_log.dart';
import 'app_preferences_provider.dart';

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
    final next = await prefs.appendSessionLog(entry);
    state = AsyncData(next);
  }

  Future<void> clear() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.clearSessionHistory();
    state = const AsyncData([]);
  }
}
