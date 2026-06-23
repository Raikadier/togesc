import '../constants/game_constants.dart';
import '../constants/notes.dart';

/// Resuelve el pool de notas para SRS segun modo, foco y preferencia del usuario.
List<String>? resolvePracticeNotePool({
  required GameMode mode,
  required List<String> configuredPool,
  String? focusNote,
}) {
  if (mode == GameMode.sharpsOnly) return sharpNotes;
  if (focusNote != null && notes.containsKey(focusNote)) return [focusNote];

  final valid = configuredPool.where(notes.containsKey).toList();
  if (valid.isEmpty || valid.length >= notes.length) return null;
  return valid;
}
