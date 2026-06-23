import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../models/engagement_stats.dart';
import '../models/note_progress_summary.dart';
import '../providers/audio_provider.dart';
import '../providers/engagement_stats_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../providers/srs_provider.dart';
import '../widgets/togesc_ui.dart';

/// Seccion Daily Focus (Stitch): notas criticas + racha/XP.
class DailyFocusSection extends ConsumerWidget {
  const DailyFocusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(practiceRecommendationsProvider);
    final engagement = ref.watch(engagementStatsProvider);
    final summaries = ref.watch(noteProgressSummariesProvider);
    final critical =
        recommendations['critical_notes'] as List<dynamic>? ?? [];

    if (recommendations.isEmpty && engagement.currentStreakDays == 0) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Enfoque diario',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            if (wide) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _CriticalNotesCard(
                        critical: critical,
                        summaries: summaries,
                        message: recommendations['message'] as String? ?? '',
                        onPractice: () => _startCriticalPractice(context, ref, critical),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      flex: 5,
                      child: _StreakXpCard(engagement: engagement),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                _CriticalNotesCard(
                  critical: critical,
                  summaries: summaries,
                  message: recommendations['message'] as String? ?? '',
                  onPractice: () => _startCriticalPractice(context, ref, critical),
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                _StreakXpCard(engagement: engagement),
              ],
            );
          },
        ),
      ],
    );
  }

  void _startCriticalPractice(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> critical,
  ) {
    ref.read(audioPlayerServiceProvider).captureUserGesture();
    if (critical.isNotEmpty) {
      final note = critical.first is (String, int)
          ? (critical.first as (String, int)).$1
          : critical.first.toString();
      ref.read(practiceFocusNoteProvider.notifier).state = note;
    }
    context.push('${AppRoutes.game}/${GameMode.singleNote.id}');
  }
}

class _CriticalNotesCard extends StatelessWidget {
  final List<dynamic> critical;
  final List<NoteProgressSummary> summaries;
  final String message;
  final VoidCallback onPractice;

  const _CriticalNotesCard({
    required this.critical,
    required this.summaries,
    required this.message,
    required this.onPractice,
  });

  double _accuracyFor(String note) {
    for (final s in summaries) {
      if (s.note == note) return s.accuracyPercent;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayNotes = critical.take(2).map((item) {
      final note = item is (String, int) ? item.$1 : item.toString();
      return (note, _accuracyFor(note));
    }).toList();

    return TogescCard(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      color: scheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: DesignTokens.borderRadiusMd,
                ),
                child: Icon(Icons.priority_high_rounded,
                    color: scheme.error, size: 20),
              ),
              const SizedBox(width: DesignTokens.spacingSm),
              Text(
                'ATENCION REQUERIDA',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          Text(
            'Tus notas criticas',
            style: theme.textTheme.titleLarge?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (displayNotes.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            Wrap(
              spacing: DesignTokens.spacingMd,
              runSpacing: DesignTokens.spacingSm,
              children: displayNotes.map((entry) {
                final (note, acc) = entry;
                return _NoteAccuracyChip(note: note, accuracy: acc);
              }).toList(),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingLg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onPractice,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Practicar ahora'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteAccuracyChip extends StatelessWidget {
  final String note;
  final double accuracy;

  const _NoteAccuracyChip({required this.note, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: DesignTokens.borderRadiusXl,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: DesignTokens.incorrect,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          SizedBox(
            width: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (accuracy / 100).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: scheme.surfaceContainer,
                color: DesignTokens.incorrect,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            '${accuracy.round()}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _StreakXpCard extends StatelessWidget {
  final EngagementStats engagement;

  const _StreakXpCard({required this.engagement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = engagement.currentStreakDays;
    final dayLabel = days == 1 ? '1 Dia' : '$days Dias';

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        gradient: DesignTokens.proGradient,
        borderRadius: DesignTokens.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RACHA Y NIVEL',
            style: theme.textTheme.labelMedium?.copyWith(
              color: DesignTokens.onPrimary.withValues(alpha: 0.85),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            dayLabel,
            style: theme.textTheme.displaySmall?.copyWith(
              color: DesignTokens.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            days > 0
                ? 'Sigue asi para mantener tu racha.'
                : 'Practica hoy para iniciar tu racha.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: DesignTokens.borderRadiusXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${engagement.xpTowardNextMilestone} XP',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: DesignTokens.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Total: ${engagement.totalXp} XP',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: DesignTokens.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: engagement.milestoneProgress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: DesignTokens.secondaryContainer,
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
