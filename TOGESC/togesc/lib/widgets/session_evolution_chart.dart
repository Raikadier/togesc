import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../utils/session_history_stats.dart';
import 'togesc_ui.dart';

/// Grafico de barras de precision diaria (Fase 7C-3).
class SessionEvolutionChart extends StatelessWidget {
  const SessionEvolutionChart({
    super.key,
    required this.summaries,
  });

  final List<DayPracticeSummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final maxRounds = summaries
        .map((day) => day.rounds)
        .fold<int>(0, (max, value) => value > max ? value : max);

    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Evolucion 7 dias',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Precision diaria y rondas practicadas (historial local).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summaries.map((day) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayBar(
                      summary: day,
                      maxRounds: maxRounds,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.summary,
    required this.maxRounds,
  });

  final DayPracticeSummary summary;
  final int maxRounds;

  Color _barColor(double accuracy) {
    if (!summary.hasActivity) {
      return DesignTokens.onSurfaceVariant.withValues(alpha: 0.15);
    }
    if (accuracy >= 80) return DesignTokens.correct;
    if (accuracy >= 50) return DesignTokens.selection;
    return DesignTokens.incorrect;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barHeightFactor = maxRounds <= 0 || !summary.hasActivity
        ? 0.08
        : (summary.rounds / maxRounds).clamp(0.12, 1.0);
    final accuracy = summary.accuracyPercent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (summary.hasActivity)
          Text(
            '${accuracy.round()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _barColor(accuracy),
              fontWeight: FontWeight.w600,
            ),
          )
        else
          const SizedBox(height: 14),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: barHeightFactor,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _barColor(accuracy),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          weekdayShortLabel(summary.day),
          style: theme.textTheme.labelMedium,
        ),
        if (summary.hasActivity)
          Text(
            '${summary.rounds}r',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
