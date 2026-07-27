import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../app/togesc_colors.dart';
import '../constants/game_constants.dart';
import '../models/note_progress_summary.dart';
import '../providers/audio_provider.dart';
import '../providers/engagement_stats_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../providers/srs_provider.dart';
import '../widgets/togesc_ui.dart';

/// Enfoque diario: notas críticas + CTA. Sin XP; la racha vive fuera (label discreto).
class DailyFocusSection extends ConsumerWidget {
  const DailyFocusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(practiceRecommendationsProvider);
    final summaries = ref.watch(noteProgressSummariesProvider);
    final critical =
        recommendations['critical_notes'] as List<dynamic>? ?? [];

    if (critical.isEmpty) {
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
        _CriticalNotesCard(
          critical: critical,
          summaries: summaries,
          message: recommendations['message'] as String? ?? '',
          onPractice: () => _startCriticalPractice(context, ref, critical),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
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

/// Racha de práctica como metadato secundario (sin XP ni card hero).
class PracticeStreakLabel extends ConsumerWidget {
  const PracticeStreakLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(engagementStatsProvider).currentStreakDays;
    if (days <= 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final dayLabel = days == 1 ? '1 día' : '$days días';

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
      child: Text(
        'Racha de práctica: $dayLabel',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
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
    final colors = TogescColors.of(context);
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
                  color: colors.incorrectContainer,
                  borderRadius: DesignTokens.borderRadiusMd,
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  color: colors.onIncorrectContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingSm),
              Text(
                'Conviene repasar',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onIncorrectContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          Text(
            'Tus notas críticas',
            style: theme.textTheme.titleLarge?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            message.isEmpty
                ? 'La precisión ha bajado en estas notas. Un repaso corto ayuda a consolidarlas.'
                : message,
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
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
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
    final colors = TogescColors.of(context);

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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.incorrect,
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
                color: colors.incorrect,
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
