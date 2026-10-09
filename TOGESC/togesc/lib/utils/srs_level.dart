import '../constants/srs_constants.dart';
import '../models/note_data.dart';
import '../models/note_progress_summary.dart';

/// Nivel SRS máximo que muestra la UI («n/5» y 5 puntos).
const int srsMaxLevel = 5;

/// Nivel SRS visible (0..5) a partir del estado de una nota.
///
/// Fórmula (rediseño v2, gap analysis §3):
/// - **Aprendizaje** (0..2): `floor(3 · consecutiveCorrect / learningThreshold)`
///   acotado a 0..2. Con umbral 5: 0–1 aciertos → 0, 2–3 → 1, 4 → 2.
/// - **Consolidada** (3..5): `3 + clamp(intervalIndex - 1, 0, 2)`.
///   Se resta 1 porque al graduarse `SRSSystem` deja `intervalIndex` en 1
///   (lo pone a 0 y `_scheduleNextReview` lo incrementa en el acierto), así
///   que recién graduada = 3, una revisión más = 4 y a partir de ahí = 5.
///   Al olvidar, `intervalIndex` baja 2 pasos y, si queda < 2, la nota vuelve
///   a aprendizaje.
///
/// [learningThreshold] sale de `SrsIntensityProfile.learningThreshold`
/// (por defecto [learningPhaseThreshold]); valores <= 0 se tratan como 1.
int srsLevelFromValues({
  required bool isLearning,
  required int consecutiveCorrect,
  required int intervalIndex,
  int learningThreshold = learningPhaseThreshold,
}) {
  if (isLearning) {
    final threshold = learningThreshold <= 0 ? 1 : learningThreshold;
    final cc = consecutiveCorrect < 0 ? 0 : consecutiveCorrect;
    final raw = (3 * cc) ~/ threshold;
    return raw.clamp(0, 2);
  }
  final step = (intervalIndex - 1).clamp(0, 2);
  return 3 + step;
}

/// Nivel SRS (0..5) de una [NoteData].
int srsLevel(
  NoteData data, {
  int learningThreshold = learningPhaseThreshold,
}) {
  return srsLevelFromValues(
    isLearning: data.isLearning,
    consecutiveCorrect: data.consecutiveCorrect,
    intervalIndex: data.intervalIndex,
    learningThreshold: learningThreshold,
  );
}

/// Nivel SRS (0..5) de un [NoteProgressSummary] (rejilla de Progreso, panel).
int srsLevelForSummary(
  NoteProgressSummary summary, {
  int learningThreshold = learningPhaseThreshold,
}) {
  return srsLevelFromValues(
    isLearning: summary.isLearning,
    consecutiveCorrect: summary.consecutiveCorrect,
    intervalIndex: summary.intervalIndex,
    learningThreshold: learningThreshold,
  );
}

/// Nivel SRS desde una instantánea `old`/`new` de
/// `SRSSystem.updateAfterResponse` (claves `is_learning`,
/// `consecutive_correct`, `interval_index`). `null` si el mapa no es válido.
int? srsLevelFromSnapshot(
  Object? snapshot, {
  int learningThreshold = learningPhaseThreshold,
}) {
  if (snapshot is! Map) return null;
  final isLearning = snapshot['is_learning'];
  final cc = snapshot['consecutive_correct'];
  final interval = snapshot['interval_index'];
  if (isLearning is! bool || cc is! num || interval is! num) return null;
  return srsLevelFromValues(
    isLearning: isLearning,
    consecutiveCorrect: cc.toInt(),
    intervalIndex: interval.toInt(),
    learningThreshold: learningThreshold,
  );
}

/// Cambio de nivel SRS de una nota en una ronda («SRS 3/5 → 4/5»).
class SrsLevelChange {
  final int before;
  final int after;

  const SrsLevelChange({required this.before, required this.after});

  bool get improved => after > before;
  bool get dropped => after < before;
}

/// Calcula el cambio de nivel a partir de una entrada de
/// `RoundResult.srsChanges[nota]` (`{'was_correct', 'old', 'new'}`).
SrsLevelChange? srsLevelChangeFromSrsChange(
  Object? change, {
  int learningThreshold = learningPhaseThreshold,
}) {
  if (change is! Map) return null;
  final before = srsLevelFromSnapshot(
    change['old'],
    learningThreshold: learningThreshold,
  );
  final after = srsLevelFromSnapshot(
    change['new'],
    learningThreshold: learningThreshold,
  );
  if (before == null || after == null) return null;
  return SrsLevelChange(before: before, after: after);
}
