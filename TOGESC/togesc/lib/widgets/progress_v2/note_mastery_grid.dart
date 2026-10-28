import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../../utils/srs_level.dart';
import '../staggered_entrance.dart';
import 'progress_metrics.dart';

/// Rejilla 4×3 de dominio por nota (Progreso v2, 1c). Gratis (D7).
///
/// - Color: `masteryColor` (umbrales <50 / 50–74 / ≥75 y tono verde por
///   nivel SRS); texto: `masteryOnColor` (AA).
/// - Nota nunca vista: «—» sobre `masteryEmpty`.
/// - A11y: el % y el estado se leen en cada celda; el color no es la única
///   señal.
/// - v2.1: las celdas entran escalonadas ([cellStagger]) y las vencidas
///   llevan el icono `schedule` («pendiente de repaso»).
class NoteMasteryGrid extends StatelessWidget {
  const NoteMasteryGrid({
    super.key,
    required this.summaries,
    required this.consolidatedCount,
    required this.inProgressCount,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
    this.onNoteTap,
    this.showHeader = true,
  });

  final List<NoteProgressSummary> summaries;
  final int consolidatedCount;
  final int inProgressCount;
  final NoteNamingMode namingMode;
  final int learningThreshold;
  final ValueChanged<NoteProgressSummary>? onNoteTap;

  /// Título y subtítulo propios. `false` dentro de la card de dominio, que
  /// ya los pinta.
  final bool showHeader;

  static const int columns = 4;

  /// Desfase de la entrada escalonada de las celdas.
  static const Duration cellStagger = Duration(milliseconds: 35);

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
        if (showHeader) ...[
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
        ],
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: DesignTokens.spacingSm),
          Row(
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: DesignTokens.spacingSm),
                Expanded(
                  child: c < rows[r].length
                      ? StaggeredEntrance(
                          index: r * columns + c,
                          step: cellStagger,
                          child: NoteMasteryCell(
                            summary: rows[r][c],
                            namingMode: namingMode,
                            learningThreshold: learningThreshold,
                            onTap: onNoteTap == null
                                ? null
                                : () => onNoteTap!(rows[r][c]),
                          ),
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

  /// Etiqueta semántica completa: «A sostenido, 42 %, crítica, nivel 1 de 5»
  /// (y «, pendiente de repaso» si está vencida).
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
    final due = summary.isOverdue ? ', pendiente de repaso' : '';
    return '$name, $pct %, ${status.label}, nivel $level de $srsMaxLevel$due';
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

    final cell = summary.isOverdue && seen
        ? Stack(
            children: [
              content,
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.schedule_rounded,
                  key: ValueKey('mastery-due-${summary.note}'),
                  size: 14,
                  color: foreground,
                ),
              ),
            ],
          )
        : content;

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
        child: onTap == null ? cell : InkWell(onTap: onTap, child: cell),
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
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 14, color: textColor),
            const SizedBox(width: DesignTokens.spacingXs),
            Text('Pendiente de repaso', style: style),
          ],
        ),
      ],
    );
  }
}
