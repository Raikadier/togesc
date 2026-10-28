import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../../models/practice_session_log.dart' show chromaticNotes;
import '../../utils/srs_level.dart';
import '../ear_map/ear_map_wheel.dart';
import '../progress_v2/progress_metrics.dart';

/// Precisión global por nota vista (aciertos / intentos de todas las notas),
/// con un decimal, como `SRSSystem.getStatistics()['accuracy_percentage']`.
/// `null` si aún no hay intentos.
double? globalAccuracyFromSummaries(List<NoteProgressSummary> summaries) {
  var seen = 0;
  var correct = 0;
  for (final s in summaries) {
    seen += s.timesSeen;
    correct += s.timesCorrect;
  }
  if (seen == 0) return null;
  return (correct / seen * 1000).round() / 10;
}

/// Notas consolidadas para la meta de octava: vistas y con ≥ 75 %.
int consolidatedNoteCount(List<NoteProgressSummary> summaries) => summaries
    .where(
      (s) =>
          s.timesSeen > 0 &&
          s.accuracyPercent >= DesignTokens.masteryGreenThreshold,
    )
    .length;

/// «68,5 %» con coma decimal (es-ES) y sin «,0».
String formatPercentEs(double value) {
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toStringAsFixed(1).replaceAll('.', ',');
  return '$text %';
}

/// Card «Mapa del oído» del Home v2.1 (SPEC §2.1.3): rueda con la precisión
/// global, leyenda, meta de octava y fila de detalle con «Practicar».
class EarMapCard extends StatefulWidget {
  const EarMapCard({
    super.key,
    required this.summaries,
    required this.onPractice,
    this.onOpenProgress,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
  });

  final List<NoteProgressSummary> summaries;

  /// «Practicar» en la fila de detalle: sesión de una sola nota.
  final ValueChanged<String> onPractice;

  /// «Ver progreso» en la cabecera.
  final VoidCallback? onOpenProgress;
  final NoteNamingMode namingMode;
  final int learningThreshold;

  @override
  State<EarMapCard> createState() => _EarMapCardState();
}

class _EarMapCardState extends State<EarMapCard> {
  NoteProgressSummary? _selected;

  @override
  void didUpdateWidget(covariant EarMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selected;
    if (selected == null) return;
    // Mantener la fila de detalle con los datos frescos de la nota.
    for (final s in widget.summaries) {
      if (s.note == selected.note) {
        _selected = s;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final accuracy = globalAccuracyFromSummaries(widget.summaries);
    final consolidated = consolidatedNoteCount(widget.summaries);
    final total = chromaticNotes.length;

    return Container(
      key: const ValueKey('home-ear-map-card'),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: DesignTokens.borderRadiusCard,
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Mapa del oído',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (widget.onOpenProgress != null)
                TextButton(
                  key: const ValueKey('ear-map-open-progress'),
                  onPressed: widget.onOpenProgress,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.brand,
                    minimumSize: const Size(
                      DesignTokens.touchTargetMin,
                      DesignTokens.touchTargetMin,
                    ),
                  ),
                  child: const Text('Ver progreso'),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: EarMapWheel(
                summaries: widget.summaries,
                namingMode: widget.namingMode,
                learningThreshold: widget.learningThreshold,
                centerValue:
                    accuracy == null ? '—' : formatPercentEs(accuracy),
                centerCaption: accuracy == null
                    ? 'sin datos todavía'
                    : 'precisión global',
                selectedNote: _selected?.note,
                onSelect: (s) => setState(() => _selected = s),
              ),
            ),
          ),
          if (_selected case final selected?) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            _NoteDetailRow(
              summary: selected,
              namingMode: widget.namingMode,
              learningThreshold: widget.learningThreshold,
              onPractice: () => widget.onPractice(selected.note),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingMd),
          const _Legend(),
          const SizedBox(height: DesignTokens.spacingMd),
          OctaveGoal(consolidated: consolidated, total: total),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  static const items = [
    (DesignTokens.masteryRed, '< 50 % crítica'),
    (DesignTokens.masteryAmber, '50–74 % en curso'),
    (DesignTokens.masteryGreen, '≥ 75 % consolidada'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        );
    return Semantics(
      label: 'Leyenda: menos de 50 % crítica, de 50 a 74 % en curso, '
          '75 % o más consolidada',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 6,
        children: [
          for (final (color, label) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(label, style: style),
              ],
            ),
        ],
      ),
    );
  }
}

/// Meta de octava: anillo pequeño y «N de 12 notas consolidadas».
class OctaveGoal extends StatelessWidget {
  const OctaveGoal({super.key, required this.consolidated, this.total = 12});

  final int consolidated;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final missing = (total - consolidated).clamp(0, total);
    final title = '$consolidated de $total notas consolidadas';
    final subtitle = missing == 0
        ? 'Dominas la octava completa'
        : 'Te faltan $missing para dominar la octava completa';

    return Semantics(
      key: const ValueKey('octave-goal'),
      container: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total == 0 ? 0 : consolidated / total),
              duration: motionDuration(context, DesignTokens.durationMedium * 3),
              curve: DesignTokens.easeOut,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: colors.earMapTrack,
                color: DesignTokens.masteryGreenDeep,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      )
                      .merge(DesignTokens.tabularNumbers),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteDetailRow extends StatelessWidget {
  const _NoteDetailRow({
    required this.summary,
    required this.namingMode,
    required this.learningThreshold,
    required this.onPractice,
  });

  final NoteProgressSummary summary;
  final NoteNamingMode namingMode;
  final int learningThreshold;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final label = formatNoteLabel(summary.note, namingMode);
    final seen = summary.timesSeen > 0;
    final pct = summary.accuracyPercent;
    final level = srsLevelForSummary(
      summary,
      learningThreshold: learningThreshold,
    );
    final status = masteryStatusFor(summary);
    final cellColor = seen ? masteryColor(pct, srsLevel: level) : colors.muted;
    final cellInk =
        seen ? masteryOnColor(pct, srsLevel: level) : colors.textPrimary;
    final statusText =
        '${status.label[0].toUpperCase()}${status.label.substring(1)}';
    final detail = seen
        ? '${pct.round()} % · ${summary.timesSeen} intentos · '
            'nivel $level de $srsMaxLevel'
        : 'Aún no la has practicado';

    return Semantics(
      key: const ValueKey('ear-map-detail'),
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: DesignTokens.borderRadiusCell,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: DesignTokens.borderRadiusCell,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cellInk,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${spokenNoteName(label)} · $statusText',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary)
                        .merge(DesignTokens.tabularNumbers),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spacingSm),
            OutlinedButton(
              key: const ValueKey('ear-map-practice'),
              onPressed: onPractice,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.brand,
                minimumSize: const Size(
                  DesignTokens.touchTargetMin,
                  DesignTokens.touchTargetMin,
                ),
              ),
              child: Text(
                'Practicar',
                semanticsLabel: 'Practicar ${spokenNoteName(label)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
