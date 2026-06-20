import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice_session_log.dart';
import 'app_preferences_provider.dart';

final practiceNotePoolProvider =
    AsyncNotifierProvider<PracticeNotePoolNotifier, List<String>>(
  PracticeNotePoolNotifier.new,
);

class PracticeNotePoolNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.practiceNotePool;
  }

  Future<void> toggleNote(String note) async {
    if (!chromaticNotes.contains(note)) return;

    final current = List<String>.from(state.valueOrNull ?? chromaticNotes);
    if (current.contains(note)) {
      if (current.length <= 1) return;
      current.remove(note);
    } else {
      current.add(note);
      current.sort(
        (a, b) => chromaticNotes.indexOf(a).compareTo(chromaticNotes.indexOf(b)),
      );
    }

    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setPracticeNotePool(current);
    state = AsyncData(current);
  }

  Future<void> selectAll() async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setPracticeNotePool(List.from(chromaticNotes));
    state = AsyncData(List.from(chromaticNotes));
  }
}
