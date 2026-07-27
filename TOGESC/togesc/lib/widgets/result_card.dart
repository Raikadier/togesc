import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../app/togesc_colors.dart';
import 'togesc_ui.dart';

/// Card premium de resultado de ronda (Stitch).
class ResultCard extends StatelessWidget {
  final bool isCorrect;
  final Set<String> correctNotes;
  final double responseTime;
  final Map<String, Map<String, dynamic>>? srsChanges;
  final VoidCallback? onViewFullReport;

  const ResultCard({
    super.key,
    required this.isCorrect,
    required this.correctNotes,
    required this.responseTime,
    this.srsChanges,
    this.onViewFullReport,
  });

  String _timeComment() {
    if (responseTime < 2.0) return '¡Rápido!';
    if (responseTime < 5.0) return 'Buen tiempo';
    return 'Tómate tu tiempo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = TogescColors.of(context);
    final color = isCorrect ? colors.correct : colors.incorrect;
    final title = isCorrect ? 'EXCELENTE' : 'INCORRECTO';
    final notesList = correctNotes.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: DesignTokens.borderRadiusXl,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: isCorrect
            ? [
                BoxShadow(
                  color: colors.correct.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusXl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacingXs),
                          Text(
                            isCorrect
                                ? 'Has identificado la nota correctamente.'
                                : 'Las notas correctas eran: ${notesList.join(", ")}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: DesignTokens.borderRadiusXl,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: DesignTokens.onPrimary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'TIEMPO',
                        value: responseTime.toStringAsFixed(1),
                        unit: 'seg',
                        valueColor: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      child: _MetricTile(
                        label: 'RITMO',
                        value: _timeComment(),
                        valueColor: isCorrect
                            ? scheme.secondary
                            : colors.incorrect,
                        italic: true,
                      ),
                    ),
                  ],
                ),
                if (srsChanges != null && srsChanges!.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacingLg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dominio de notas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onViewFullReport ??
                            () => context.push(AppRoutes.statisticsNotes),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingSm,
                          ),
                        ),
                        child: const Text('Ver reporte completo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                  ...srsChanges!.entries.map(
                    (entry) => _SrsNoteRow(
                      note: entry.key,
                      newData: entry.value['new'] as Map<String, dynamic>,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color valueColor;
  final bool italic;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.unit,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: DesignTokens.borderRadiusXl,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w800,
                    fontStyle: italic ? FontStyle.italic : null,
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SrsNoteRow extends StatelessWidget {
  final String note;
  final Map<String, dynamic> newData;

  const _SrsNoteRow({required this.note, required this.newData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final consecutive = newData['consecutive_correct'] as int? ?? 0;
    final isLearning = newData['is_learning'] as bool? ?? true;
    final threshold = newData['learning_threshold'] as int? ?? 5;
    final statusLabel = isLearning ? 'Aprendiendo' : 'Consolidada';
    final colors = TogescColors.of(context);
    final statusColor = isLearning ? colors.selection : colors.correct;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: TogescCard(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        color: scheme.surfaceContainer,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: DesignTokens.borderRadiusMd,
              ),
              alignment: Alignment.center,
              child: Text(
                note,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingXs),
                      Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isLearning)
              _LearningPills(
                filled: consecutive,
                total: threshold,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingSm,
                  vertical: DesignTokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colors.correct.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'OK',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.correct,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pills de progreso SRS (Stitch: 5 segmentos en chip).
class _LearningPills extends StatelessWidget {
  final int filled;
  final int total;

  const _LearningPills({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = total.clamp(1, 8);

    return Semantics(
      label: 'Progreso $filled de $n',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSm,
          vertical: DesignTokens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i < filled
                      ? scheme.primaryContainer
                      : scheme.outlineVariant.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
