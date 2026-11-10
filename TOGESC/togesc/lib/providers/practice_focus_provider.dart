import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/notes.dart';

/// Máximo de notas de foco de una sesión. v2 (D11) eran 3; v2.1 deja
/// elegir hasta 4 en «Ajustar enfoque y duración». El plan automático
/// sigue proponiendo 3 (`selectTodayFocusNotes`).
const int maxPracticeFocusNotes = 4;

/// Nota única «practicar esta nota» (flujo anterior a v2: detalle de nota,
/// pendientes). Si está fijada, la sesión usa SOLO esa nota como pool.
/// Tiene prioridad sobre [practiceFocusNotesProvider].
final practiceFocusNoteProvider = StateProvider<String?>((ref) => null);

/// Notas de foco de la «Sesión de hoy» (hasta [maxPracticeFocusNotes]).
///
/// A diferencia de [practiceFocusNoteProvider], NO restringe el pool: la
/// sesión las prioriza en una parte de las rondas y el resto usa el pool
/// configurado (ver `resolveFocusRoundPool`).
final practiceFocusNotesProvider =
    StateProvider<List<String>>((ref) => const []);

/// Aleatoriedad para decidir qué rondas son de foco (sobrescribible en tests).
final practiceFocusRandomProvider = Provider<Random>((ref) => Random());

/// Filtra notas válidas, quita duplicados y limita a [maxPracticeFocusNotes].
List<String> normalizePracticeFocusNotes(Iterable<String> candidates) {
  final result = <String>[];
  for (final note in candidates) {
    if (!notes.containsKey(note) || result.contains(note)) continue;
    result.add(note);
    if (result.length >= maxPracticeFocusNotes) break;
  }
  return result;
}

/// Fija las notas de foco de la próxima sesión (normalizadas).
void setPracticeFocusNotes(WidgetRef ref, Iterable<String> focusNotes) {
  ref.read(practiceFocusNotesProvider.notifier).state =
      normalizePracticeFocusNotes(focusNotes);
}

/// Limpia el foco de la sesión: la nota única y la lista de foco.
void clearPracticeFocusNote(WidgetRef ref) {
  ref.read(practiceFocusNoteProvider.notifier).state = null;
  ref.read(practiceFocusNotesProvider.notifier).state = const [];
}
