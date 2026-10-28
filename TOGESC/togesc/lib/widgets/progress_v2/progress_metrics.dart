/// Cálculos puros de la pantalla Progreso v2 (1c).
library;

import '../../app/design_tokens.dart';
import '../../models/note_progress_summary.dart';

/// Latencia media global **aproximada**, en segundos.
///
/// `NoteData.avgResponseTimeSec` es una media móvil exponencial por nota; la
/// global es su media ponderada por `timesSeen`, ignorando las notas sin
/// latencia. `null` si no hay ninguna. Por eso la UI la rotula «aprox.».
double? approximateMeanLatencySec(List<NoteProgressSummary> summaries) {
  var weighted = 0.0;
  var weight = 0;
  for (final s in summaries) {
    if (s.avgResponseTimeSec <= 0 || s.timesSeen <= 0) continue;
    weighted += s.avgResponseTimeSec * s.timesSeen;
    weight += s.timesSeen;
  }
  if (weight == 0) return null;
  return weighted / weight;
}

/// Porcentaje (0–100) de la meta de precisión alcanzado, acotado.
double goalProgressPercent(
  double accuracy, {
  double goal = DesignTokens.accuracyGoalPercent,
}) {
  if (goal <= 0 || accuracy.isNaN) return 0;
  return (accuracy / goal * 100).clamp(0, 100).toDouble();
}

/// Estado legible de una celda de dominio (no depende solo del color).
enum MasteryStatus {
  unseen('sin datos'),
  critical('crítica'),
  inProgress('en curso'),
  mastered('dominada');

  const MasteryStatus(this.label);

  final String label;
}

MasteryStatus masteryStatusFor(NoteProgressSummary summary) {
  if (summary.timesSeen <= 0) return MasteryStatus.unseen;
  final pct = summary.accuracyPercent;
  if (pct < DesignTokens.masteryAmberThreshold) return MasteryStatus.critical;
  if (pct < DesignTokens.masteryGreenThreshold) return MasteryStatus.inProgress;
  return MasteryStatus.mastered;
}

/// Nombre hablado de una nota para lectores de pantalla: «A sostenido»,
/// «La sostenido». [label] es el nombre ya formateado (letra o solfeo).
String spokenNoteName(String label) {
  if (label.endsWith('#')) {
    return '${label.substring(0, label.length - 1)} sostenido';
  }
  return label;
}

/// Texto del delta semanal: «+4.1 pts», «−2.0 pts», «±0.0 pts».
String formatDeltaPoints(double delta) {
  final abs = delta.abs().toStringAsFixed(1);
  if (abs == '0.0') return '±0.0 pts';
  return delta > 0 ? '+$abs pts' : '−$abs pts';
}

/// Número con separador de miles fino: 1284 → «1 284».
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
