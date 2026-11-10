/// Cálculos puros de la pantalla Progreso v2 (1c).
library;

import '../../app/design_tokens.dart';
import '../../models/note_progress_summary.dart';
import '../../utils/number_format.dart';
import 'package:flutter/material.dart';
import '../../app/togesc_colors.dart';
import '../../constants/srs_constants.dart';

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

/// Estado de una nota. Único sitio donde se decide: lo usan la rueda, la
/// rejilla, el Home, la sesión y las hojas de detalle (v2.2, lote B).
enum MasteryStatus {
  unseen('sin datos'),

  /// Vista, pero con menos de [masteryMinAttempts] intentos: aún no se juzga.
  measuring('midiendo'),
  critical('a reforzar'),
  inProgress('en curso'),
  mastered('consolidada');

  const MasteryStatus(this.label);

  final String label;

  /// «A reforzar», «En curso»… con mayúscula inicial.
  String get title => '${label[0].toUpperCase()}${label.substring(1)}';

  /// Hay datos suficientes para mostrar color y porcentaje.
  bool get isJudged =>
      this != MasteryStatus.unseen && this != MasteryStatus.measuring;
}

/// Estado a partir de los intentos y la precisión (0–100). Función pura.
MasteryStatus masteryStatusOf({required int timesSeen, required double pct}) {
  if (timesSeen <= 0) return MasteryStatus.unseen;
  if (timesSeen < masteryMinAttempts) return MasteryStatus.measuring;
  if (pct.isNaN || pct < DesignTokens.masteryAmberThreshold) {
    return MasteryStatus.critical;
  }
  if (pct < DesignTokens.masteryGreenThreshold) return MasteryStatus.inProgress;
  return MasteryStatus.mastered;
}

MasteryStatus masteryStatusFor(NoteProgressSummary summary) => masteryStatusOf(
      timesSeen: summary.timesSeen,
      pct: summary.accuracyPercent,
    );

/// Subtítulo de «Dominio por nota»: empieza siempre por las consolidadas y
/// añade solo los estados que tienen notas.
/// «0 consolidadas · 2 a reforzar · 3 midiendo · 7 sin datos».
String masterySubtitle(List<NoteProgressSummary> summaries) {
  final counts = <MasteryStatus, int>{};
  for (final s in summaries) {
    final status = masteryStatusFor(s);
    counts[status] = (counts[status] ?? 0) + 1;
  }
  int n(MasteryStatus status) => counts[status] ?? 0;
  final solid = n(MasteryStatus.mastered);
  return [
    '$solid ${solid == 1 ? 'consolidada' : 'consolidadas'}',
    if (n(MasteryStatus.inProgress) > 0)
      '${n(MasteryStatus.inProgress)} en curso',
    if (n(MasteryStatus.critical) > 0)
      '${n(MasteryStatus.critical)} a reforzar',
    if (n(MasteryStatus.measuring) > 0)
      '${n(MasteryStatus.measuring)} midiendo',
    if (n(MasteryStatus.unseen) > 0) '${n(MasteryStatus.unseen)} sin datos',
  ].join(' · ');
}

/// «2 de 5»: intentos hechos sobre los necesarios para juzgar la nota.
String measuringProgressLabel(int timesSeen) =>
    '$timesSeen de $masteryMinAttempts';

/// Fondo y tinta de una celda de nota según su estado.
/// - Sin datos: superficie apagada del tema.
/// - Midiendo: neutro (primario atenuado), nunca rojo.
/// - Con datos: la escala de dominio y su par AA.
({Color background, Color foreground}) masteryCellColors(
  BuildContext context,
  NoteProgressSummary summary, {
  required int level,
}) {
  final colors = TogescColors.of(context);
  switch (masteryStatusFor(summary)) {
    case MasteryStatus.unseen:
      return (background: colors.muted, foreground: colors.textPrimary);
    case MasteryStatus.measuring:
      return (
        background: masteryMeasuringColor(context),
        foreground: colors.textPrimary,
      );
    case MasteryStatus.critical:
    case MasteryStatus.inProgress:
    case MasteryStatus.mastered:
      final pct = summary.accuracyPercent;
      return (
        background: masteryColor(pct, srsLevel: level),
        foreground: masteryOnColor(pct, srsLevel: level),
      );
  }
}

/// Color neutro de una nota que aún se está midiendo.
Color masteryMeasuringColor(BuildContext context) => Color.alphaBlend(
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
      TogescColors.of(context).muted,
    );

/// Nombre hablado de una nota para lectores de pantalla: «A sostenido»,
/// «La sostenido». [label] es el nombre ya formateado (letra o solfeo).
String spokenNoteName(String label) {
  if (label.endsWith('#')) {
    return '${label.substring(0, label.length - 1)} sostenido';
  }
  return label;
}

/// Texto del delta semanal: «+4,1 pts», «−2,0 pts», «±0,0 pts».
String formatDeltaPoints(double delta) {
  final abs = formatDecimalEs(delta.abs());
  if (abs == '0,0') return '±0,0 pts';
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
