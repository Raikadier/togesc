import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice_session_preferences.dart';
import 'app_preferences_provider.dart';

final practiceSessionPreferencesProvider =
    AsyncNotifierProvider<PracticeSessionPreferencesNotifier,
        PracticeSessionPreferences>(
  PracticeSessionPreferencesNotifier.new,
);

class PracticeSessionPreferencesNotifier
    extends AsyncNotifier<PracticeSessionPreferences> {
  @override
  Future<PracticeSessionPreferences> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.practiceSessionPreferences;
  }

  Future<void> save(PracticeSessionPreferences value) async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setPracticeSessionPreferences(value);
    state = AsyncData(value);
  }

  Future<void> setRoundGoal(SessionRoundGoal goal) async {
    final current = state.valueOrNull ?? const PracticeSessionPreferences();
    await save(current.copyWith(roundGoal: goal));
  }

  Future<void> setAutoAdvanceAfterResult(bool enabled) async {
    final current = state.valueOrNull ?? const PracticeSessionPreferences();
    await save(current.copyWith(autoAdvanceAfterResult: enabled));
  }
}
