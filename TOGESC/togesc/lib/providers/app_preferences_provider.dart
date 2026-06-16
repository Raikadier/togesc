import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/note_naming.dart';
import '../services/app_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AppPreferences(prefs);
});

final noteNamingModeProvider =
    AsyncNotifierProvider<NoteNamingModeNotifier, NoteNamingMode>(
  NoteNamingModeNotifier.new,
);

class NoteNamingModeNotifier extends AsyncNotifier<NoteNamingMode> {
  @override
  Future<NoteNamingMode> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.noteNamingMode;
  }

  Future<void> setMode(NoteNamingMode mode) async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setNoteNamingMode(mode);
    state = AsyncData(mode);
  }
}

final practiceRemindersEnabledProvider =
    AsyncNotifierProvider<PracticeRemindersNotifier, bool>(
  PracticeRemindersNotifier.new,
);

class PracticeRemindersNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.practiceRemindersEnabled;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setPracticeRemindersEnabled(value);
    state = AsyncData(value);
  }
}
