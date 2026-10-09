import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../../utils/srs_level.dart';
import 'progress_metrics.dart';

/// Rejilla 4×3 de dominio por nota (Progreso v2, 1c). Gratis (D7).
///
/// - Color: `masteryColor` (umbrales <50 / 50–74 / ≥75 y tono verde por
///   nivel SRS); texto: `masteryOnColor` (AA).
/// - Nota nunca vista: «—» sobre `masteryEmpty`.
/// - A11y: el % y el estado se leen en cada celda; el color no es la única
///   señal.
class NoteMasteryGrid extends StatelessWidget {
  const NoteMasteryGrid({
    super.key,
    required this.summaries,
    required this.consolidatedCount,
    required this.inProgressCount,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
    this.onNoteTap,
  });

  final List<NoteProgressSummary> summaries;
  final int consolidatedCount;
  final int inProgressCount;
  final NoteNamingMode namingMode;
  final int learningThreshold;
  final ValueChanged<NoteProgressSummary>? onNoteTap;

  static const int columns = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = <List<NoteProgressSummary>>[
      for (var i = 0; i < summaries.length; i += columns)
        summaries.sublist(
          i,
          i + columns > summaries.length ? summaries.length : i + columns,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Dominio por nota',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          '$consolidatedCount consolidadas · $inProgressCount en curso',
          key: const Key('progress-mastery-subtitle'),
          style: theme.textTheme.bodyMedium
              ?.merge(DesignTokens.tabularNumbers)
              .copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: DesignTokens.spacingSm),
          Row(
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: DesignTokens.spacingSm),
                Expanded(
                  child: c < rows[r].length
                      ? NoteMasteryCell(
                          summary: rows[r][c],
                          namingMode: namingMode,
                          learningThreshold: learningThreshold,
                          onTap: onNoteTap == null
                              ? null
                              : () => onNoteTap!(rows[r][c]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: DesignTokens.spacingMd),
        const MasteryLegend(),
      ],
    );
  }
}

/// Celda de la rejilla de dominio.
class NoteMasteryCell extends StatelessWidget {
  const NoteMasteryCell({
    super.key,
    required this.summary,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
    this.onTap,
  });

  final NoteProgressSummary summary;
  final NoteNamingMode namingMode;
  final int learningThreshold;
  final VoidCallback? onTap;

  static const double height = 68;

  /// Etiqueta semántica completa: «A sostenido, 42 %, crítica, nivel 1 de 5».
  static String semanticsLabelFor(
    NoteProgressSummary summary, {
    NoteNamingMode namingMode = NoteNamingMode.letter,
    int learningThreshold = 5,
  }) {
    final name = spokenNoteName(formatNoteLabel(summary.note, namingMode));
    final status = masteryStatusFor(summary);
    if (status == MasteryStatus.unseen) {
      return '$name, sin datos todavía';
    }
    final pct = summary.accuracyPercent.round();
    final level = srsLevelForSummary(
      summary,
      learningThreshold: learningThreshold,
    );
    return '$name, $pct %, ${status.label}, nivel $level de $srsMaxLevel';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seen = summary.timesSeen > 0;
    final pct = summary.accuracyPercent;
    final level = srsLevelForSummary(
      summary,
      learningThreshold: learningThreshold,
    );
    // Sin datos: superficie apagada del tema (#F3ECF1 / #241B2A) con texto
    // principal. Las celdas con datos llevan su propio par AA.
    final colors = TogescColors.of(context);
    final background = seen
        ? masteryColor(pct, srsLevel: level)
        : colors.muted;
    final foreground = seen
        ? masteryOnColor(pct, srsLevel: level)
        : colors.textPrimary;
    final label = formatNoteLabel(summary.note, namingMode);

    final content = SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingXs,
          vertical: DesignTokens.spacingSm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                seen ? '${pct.round()}%' : '—',
                style: theme.textTheme.labelLarge
                    ?.merge(DesignTokens.tabularNumbers)
                    .copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      label: semanticsLabelFor(
        summary,
        namingMode: namingMode,
        learningThreshold: learningThreshold,
      ),
      button: onTap != null,
      excludeSemantics: true,
      child: Material(
        key: ValueKey('mastery-cell-${summary.note}'),
        color: background,
        borderRadius: DesignTokens.borderRadiusCell,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Leyenda de la rejilla: color + rango en texto (no solo color).
class MasteryLegend extends StatelessWidget {
  const MasteryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final items = [
      (DesignTokens.masteryRed, 'Crítica <50%'),
      (DesignTokens.masteryAmber, 'En curso 50–74%'),
      (DesignTokens.masteryGreenLight, 'Dominada ≥75%'),
      (colors.muted, 'Sin datos'),
    ];

    return Wrap(
      key: const Key('progress-mastery-legend'),
      spacing: DesignTokens.spacingMd,
      runSpacing: DesignTokens.spacingXs,
      children: [
        for (final (color, text) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  border: color == colors.muted
                      ? Border.all(color: colors.cardBorder)
                      : null,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(text, style: style),
            ],
          ),
      ],
    );
  }
}
