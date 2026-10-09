import 'dart:math';

import '../constants/game_constants.dart';
import '../constants/notes.dart';

/// Proporción de rondas que se juegan solo con las notas de foco (D11).
///
/// El resto de rondas usa el pool configurado, donde las notas de foco siguen
/// pudiendo salir por SRS. Así las prioriza sin que la sesión sea adivinable.
const double focusRoundShare = 0.6;

/// Resuelve el pool de notas para SRS segun modo, foco y preferencia del usuario.
///
/// [focusNote] es el foco de nota única (flujo «practicar esta nota»): si es
/// válida, el pool es solo esa nota.
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

/// Pool de UNA ronda con notas de foco priorizadas (rediseño v2, D11).
///
/// - Sin foco válido, o en `sharpsOnly`: igual que [resolvePracticeNotePool].
/// - Con probabilidad [share] (por defecto [focusRoundShare]) la ronda usa
///   solo las notas de foco, siempre que haya al menos [numNotes] de ellas
///   (si no, `SRSSystem.selectNotes` no podría elegir notas distintas).
/// - En el resto de rondas se usa el pool configurado.
///
/// [random] se inyecta para que los tests sean deterministas.
List<String>? resolveFocusRoundPool({
  required GameMode mode,
  required List<String> configuredPool,
  required List<String> focusNotes,
  required int numNotes,
  required Random random,
  double share = focusRoundShare,
}) {
  final basePool = resolvePracticeNotePool(
    mode: mode,
    configuredPool: configuredPool,
  );
  if (mode == GameMode.sharpsOnly) return basePool;

  final validFocus = <String>[];
  for (final note in focusNotes) {
    if (notes.containsKey(note) && !validFocus.contains(note)) {
      validFocus.add(note);
    }
  }
  if (validFocus.isEmpty || validFocus.length < numNotes) return basePool;

  if (random.nextDouble() < share) return validFocus;
  return basePool;
}
