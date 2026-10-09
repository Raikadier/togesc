import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../utils/calendar_week.dart';
import 'progress_metrics.dart';

/// Cabecera de Progreso v2: precisión global, delta semanal y meta.
///
/// D10: la precisión global es **por nota** (SRS) y el delta es **por
/// rondas** (historial). El delta se rotula como «precisión de rondas» y solo
/// aparece si hay datos de las dos semanas.
class GlobalAccuracyHeader extends StatelessWidget {
  const GlobalAccuracyHeader({
    super.key,
    required this.accuracy,
    required this.delta,
    this.goal = DesignTokens.accuracyGoalPercent,
  });

  /// Precisión global del SRS (0–100), por nota vista.
  final double accuracy;
  final WeeklyAccuracyDelta delta;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goalPct = goalProgressPercent(accuracy, goal: goal);
    final accuracyText = '${accuracy.toStringAsFixed(1)}%';
    final goalText = '${goalPct.round()}% de la meta (${goal.round()}%)';
    final deltaPoints = delta.deltaPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRECISIÓN GLOBAL',
          style: DesignTokens.overline.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Semantics(
          label: 'Precisión global por nota: $accuracyText',
          excludeSemantics: true,
          child: Text(
            accuracyText,
            key: const Key('progress-global-accuracy'),
            style: DesignTokens.bigNumberLarge.copyWith(
              color: scheme.primary,
            ),
          ),
        ),
        if (deltaPoints != null) ...[
          const SizedBox(height: DesignTokens.spacingSm),
          _DeltaLine(deltaPoints: deltaPoints),
        ],
        const SizedBox(height: DesignTokens.spacingMd),
        Semantics(
          label: goalText,
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: DesignTokens.borderRadiusPill,
                child: LinearProgressIndicator(
                  value: goalPct / 100,
                  minHeight: 8,
                  backgroundColor: TogescColors.of(context).muted,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                goalText,
                style: theme.textTheme.labelMedium
                    ?.merge(DesignTokens.tabularNumbers)
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeltaLine extends StatelessWidget {
  const _DeltaLine({required this.deltaPoints});

  final double deltaPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final up = deltaPoints >= 0.05;
    final down = deltaPoints <= -0.05;
    final feedback = TogescColors.of(context);
    final color = up
        ? feedback.correct
        : down
            ? feedback.incorrect
            : scheme.onSurfaceVariant;
    final icon = up
        ? Icons.trending_up_rounded
        : down
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final text = '${formatDeltaPoints(deltaPoints)} vs. semana pasada';

    return Semantics(
      label: 'Precisión de rondas: $text',
      excludeSemantics: true,
      child: Row(
        key: const Key('progress-weekly-delta'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: DesignTokens.spacingXs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' · precisión de rondas',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium?.merge(
                DesignTokens.tabularNumbers,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
