import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../models/note_progress_summary.dart';
import '../providers/practice_focus_provider.dart';
import 'togesc_ui.dart';

/// Fila de nota con barra de precision y latencia.
class StatsNoteRow extends StatelessWidget {
  final NoteProgressSummary summary;
  final bool highlightError;

  const StatsNoteRow({
    super.key,
    required this.summary,
    this.highlightError = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final acc = summary.accuracyPercent;
    final color =
        highlightError ? DesignTokens.incorrect : scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.note,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                ),
                if (summary.avgResponseTimeSec > 0)
                  Text(
                    '${summary.avgResponseTimeSec.toStringAsFixed(1)}s latencia',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.outline,
                        ),
                  ),
              ],
            ),
          ),
          Text(
            '${acc.round()}%',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          SizedBox(
            width: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (acc / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHigh,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid bento superior de estadisticas (Stitch).
class StatsBentoHeader extends StatelessWidget {
  final double accuracy;
  final int totalSeen;
  final int overdueCount;
  final VoidCallback onReviewNow;

  const StatsBentoHeader({
    super.key,
    required this.accuracy,
    required this.totalSeen,
    required this.overdueCount,
    required this.onReviewNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const goal = 90.0;
    final goalProgress = (accuracy / goal).clamp(0.0, 1.0);

    final precisionCard = TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRECISION GLOBAL',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.outline,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${accuracy.toStringAsFixed(1)}%',
            style: theme.textTheme.displaySmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goalProgress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHigh,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );

    final attemptsCard = TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.analytics_rounded, color: scheme.secondary),
          Text(
            'INTENTOS TOTALES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.outline,
              letterSpacing: 1,
            ),
          ),
          Text(
            '$totalSeen',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );

    final pendingCard = Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        gradient: DesignTokens.proGradient,
        borderRadius: DesignTokens.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PENDIENTES HOY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: DesignTokens.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          Text(
            '$overdueCount',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: DesignTokens.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          FilledButton(
            onPressed: overdueCount > 0 ? onReviewNow : null,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.surfaceContainerLowest,
              foregroundColor: scheme.primary,
            ),
            child: const Text('Repasar ahora'),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 520) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: precisionCard),
                const SizedBox(width: DesignTokens.spacingMd),
                Expanded(child: attemptsCard),
                const SizedBox(width: DesignTokens.spacingMd),
                Expanded(child: pendingCard),
              ],
            ),
          );
        }
        return Column(
          children: [
            precisionCard,
            const SizedBox(height: DesignTokens.spacingMd),
            attemptsCard,
            const SizedBox(height: DesignTokens.spacingMd),
            pendingCard,
          ],
        );
      },
    );
  }
}

void startReviewPractice(BuildContext context, WidgetRef ref) {
  ref.read(practiceFocusNoteProvider.notifier).state = null;
  context.push('${AppRoutes.game}/${GameMode.singleNote.id}');
}
