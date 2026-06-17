import 'dart:collection';

import '../constants/game_constants.dart';

/// Seleccion de notas en el piano acorde al numero permitido por el modo.
LinkedHashSet<String> togglePianoNoteSelection({
  required Set<String> current,
  required String note,
  required int maxNotes,
}) {
  assert(maxNotes >= 1);

  final next = LinkedHashSet<String>.from(current);

  if (next.contains(note)) {
    next.remove(note);
    return next;
  }

  if (maxNotes == 1) {
    return LinkedHashSet<String>()..add(note);
  }

  while (next.length >= maxNotes) {
    next.remove(next.first);
  }
  next.add(note);

  return next;
}

String pianoSelectionRequiredMessage(int requiredNotes) {
  if (requiredNotes == 1) {
    return 'Debes seleccionar 1 nota para confirmar.';
  }
  return 'Debes seleccionar exactamente $requiredNotes notas para confirmar.';
}

bool canConfirmPianoSelection(Set<String> selected, int requiredNotes) {
  return selected.length == requiredNotes;
}

/// Resuelve cuantas notas admite la seleccion en pantalla de respuesta.
int selectableNoteCount({
  required GameMode screenMode,
  required int sessionNumNotes,
}) {
  final fixed = fixedNoteCountForMode(screenMode);
  if (fixed != null) return fixed;
  if (sessionNumNotes >= 1) return sessionNumNotes;
  return randomMinNotes;
}
