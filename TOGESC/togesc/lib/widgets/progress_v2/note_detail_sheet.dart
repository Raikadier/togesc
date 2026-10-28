import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../../utils/srs_level.dart';
import 'progress_metrics.dart';

/// Frase pedagógica de la hoja de detalle según el estado de la nota.
String noteDetailAdvice(MasteryStatus status) => switch (status) {
      MasteryStatus.unseen =>
        'Aún no la has practicado. Una sesión corta basta para que el SRS '
            'empiece a conocerla.',
      MasteryStatus.critical =>
        'Esta nota aparece con más frecuencia hasta que superes el 50 %.',
      MasteryStatus.inProgress =>
        'Vas bien. Sube de nivel acertándola en sesiones distintas.',
      MasteryStatus.mastered =>
        'Consolidada. El SRS la repasa a intervalos cada vez más largos.',
    };

/// Hoja «Detalle de nota» de Progreso v2.1 (SPEC §2.3.5): celda grande,
/// estado, precisión, intentos y latencia media (de [NoteProgressSummary]),
/// pista de nivel SRS 1–5, una frase según el estado y las acciones
/// «Escuchar» y «Practicar esta nota».
class NoteDetailSheet extends StatelessWidget {
  const NoteDetailSheet({
    super.key,
    required this.summary,
    required this.onListen,
    required this.onPractice,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
  });

  final NoteProgressSummary summary;
  final VoidCallback onListen;
  final VoidCallback onPractice;
  final NoteNamingMode namingMode;
  final int learningThreshold;

  static const double cellSize = 88;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final label = formatNoteLabel(summary.note, namingMode);
    final spoken = spokenNoteName(label);
    final status = masteryStatusFor(summary);
    final seen = summary.timesSeen > 0;
    final pct = summary.accuracyPercent;
    final level = srsLevelForSummary(
      summary,
      learningThreshold: learningThreshold,
    );
    final cellColor = seen ? masteryColor(pct, srsLevel: level) : colors.muted;
    final cellInk =
        seen ? masteryOnColor(pct, srsLevel: level) : colors.textPrimary;
    final statusText =
        '${status.label[0].toUpperCase()}${status.label.substring(1)}'
        '${summary.isOverdue ? ' · pendiente de repaso' : ''}';
    final latency = summary.avgResponseTimeSec > 0 && seen
        ? '${summary.avgResponseTimeSec.toStringAsFixed(1).replaceAll('.', ',')} s'
        : '—';

    return SingleChildScrollView(
      key: const ValueKey('note-detail-sheet'),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        0,
        DesignTokens.spacingLg,
        DesignTokens.spacingLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DETALLE DE NOTA',
                  style: DesignTokens.overline.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: DesignTokens.borderRadiusCard,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacingSm),
                      child: Text(
                        label,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: cellInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        spoken,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      statusText,
                      key: const ValueKey('note-detail-status'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  key: const ValueKey('note-detail-accuracy'),
                  value: seen ? '${pct.round()} %' : '—',
                  label: 'Precisión',
                ),
              ),
              Expanded(
                child: _Stat(
                  key: const ValueKey('note-detail-attempts'),
                  value: '${summary.timesSeen}',
                  label: 'Intentos',
                ),
              ),
              Expanded(
                child: _Stat(
                  key: const ValueKey('note-detail-latency'),
                  value: latency,
                  label: 'Latencia',
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Text(
            'Nivel SRS $level de $srsMaxLevel',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          ExcludeSemantics(child: _LevelTrack(level: level)),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            noteDetailAdvice(status),
            key: const ValueKey('note-detail-advice'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg + 4),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: OutlinedButton.icon(
                  key: const ValueKey('note-detail-listen'),
                  onPressed: onListen,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      DesignTokens.touchTargetMin,
                    ),
                  ),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(
                    'Escuchar',
                    semanticsLabel: 'Escuchar $spoken',
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                flex: 14,
                child: FilledButton.icon(
                  key: const ValueKey('note-detail-practice'),
                  onPressed: onPractice,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      DesignTokens.touchTargetMin,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    'Practicar esta nota',
                    semanticsLabel: 'Practicar $spoken',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                )
                .merge(DesignTokens.tabularNumbers),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pista de 5 segmentos con los niveles alcanzados en `brand`.
class _LevelTrack extends StatelessWidget {
  const _LevelTrack({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    return Row(
      children: [
        for (var k = 1; k <= srsMaxLevel; k++) ...[
          if (k > 1) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: k <= level ? colors.brand : colors.muted,
                borderRadius: DesignTokens.borderRadiusPill,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
