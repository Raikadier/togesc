import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/game_constants.dart';
import '../models/last_practice_session.dart';
import 'app_preferences_provider.dart';

final lastPracticeSessionProvider =
    AsyncNotifierProvider<LastPracticeSessionNotifier, LastPracticeSession?>(
  LastPracticeSessionNotifier.new,
);

class LastPracticeSessionNotifier extends AsyncNotifier<LastPracticeSession?> {
  @override
  Future<LastPracticeSession?> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.lastPracticeSession;
  }

  Future<void> record({
    required GameMode mode,
    required PracticeKind kind,
  }) async {
    if (mode == GameMode.exit || mode == GameMode.speedTraining) return;

    final session = LastPracticeSession(
      modeId: mode.id,
      kind: kind,
      practicedAt: DateTime.now(),
    );
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setLastPracticeSession(session);
    state = AsyncData(session);
  }
}
