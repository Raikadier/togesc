import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../../utils/srs_level.dart';
import 'progress_metrics.dart';

/// Las [count] notas vistas más difíciles (menor precisión) y más fáciles
/// (mayor precisión), sin repetir notas entre las dos listas. Con menos de
/// dos notas vistas no hay extremos.
({List<NoteProgressSummary> hardest, List<NoteProgressSummary> easiest})
    noteExtremes(List<NoteProgressSummary> summaries, {int count = 3}) {
  final seen = summaries.where((s) => s.timesSeen > 0).toList()
    ..sort((a, b) {
      final cmp = a.accuracyPercent.compareTo(b.accuracyPercent);
      return cmp != 0 ? cmp : a.note.compareTo(b.note);
    });
  if (seen.length < 2) return (hardest: const [], easiest: const []);
  final per = (seen.length ~/ 2).clamp(1, count);
  return (
    hardest: seen.take(per).toList(),
    easiest: seen.reversed.take(per).toList(),
  );
}

/// «Tus extremos» (Pro, SPEC §2.3.6): 3 notas más difíciles y 3 más fáciles.
/// Sin acceso Pro se muestra una card con candado que abre el paywall.
class NoteExtremes extends StatelessWidget {
  const NoteExtremes({
    super.key,
    required this.summaries,
    required this.unlocked,
    required this.onUnlock,
    this.onNoteTap,
    this.namingMode = NoteNamingMode.letter,
    this.learningThreshold = 5,
  });

  final List<NoteProgressSummary> summaries;
  final bool unlocked;
  final VoidCallback onUnlock;
  final ValueChanged<NoteProgressSummary>? onNoteTap;
  final NoteNamingMode namingMode;
  final int learningThreshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Tus extremos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingSm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.pro,
            borderRadius: DesignTokens.borderRadiusPill,
          ),
          child: Text(
            'PRO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: DesignTokens.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );

    if (!unlocked) {
      return Column(
        key: const Key('progress-extremes'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: DesignTokens.spacingSm),
          Material(
            color: colors.tile,
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusCard,
              side: BorderSide(color: colors.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('progress-extremes-locked'),
              onTap: onUnlock,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded, color: colors.proAccent),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      child: Text(
                        'Descubre tus 3 notas más difíciles y las 3 más '
                        'fáciles con TOGESC Pro.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: colors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final extremes = noteExtremes(summaries);
    if (extremes.hardest.isEmpty) {
      return Column(
        key: const Key('progress-extremes'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            'Practica al menos dos notas para ver tus extremos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    }

    Widget list(
      String title,
      IconData icon,
      Color iconColor,
      List<NoteProgressSummary> items,
      String key,
    ) {
      return Container(
        key: Key(key),
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
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
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: DesignTokens.spacingXs),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            for (final s in items) _ExtremeRow(
              summary: s,
              namingMode: namingMode,
              learningThreshold: learningThreshold,
              onTap: onNoteTap == null ? null : () => onNoteTap!(s),
            ),
          ],
        ),
      );
    }

    final feedback = TogescColors.of(context);
    final hard = list(
      'Más difíciles',
      Icons.south_rounded,
      feedback.incorrect,
      extremes.hardest,
      'progress-extremes-hard',
    );
    final easy = list(
      'Más fáciles',
      Icons.north_rounded,
      feedback.correct,
      extremes.easiest,
      'progress-extremes-easy',
    );

    return Column(
      key: const Key('progress-extremes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: DesignTokens.spacingSm),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 480) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: hard),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Expanded(child: easy),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hard,
                const SizedBox(height: DesignTokens.spacingSm),
                easy,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ExtremeRow extends StatelessWidget {
  const _ExtremeRow({
    required this.summary,
    required this.namingMode,
    required this.learningThreshold,
    this.onTap,
  });

  final NoteProgressSummary summary;
  final NoteNamingMode namingMode;
  final int learningThreshold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final label = formatNoteLabel(summary.note, namingMode);
    final pct = summary.accuracyPercent;
    final level = srsLevelForSummary(
      summary,
      learningThreshold: learningThreshold,
    );
    final spoken = spokenNoteName(label);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: masteryColor(pct, srsLevel: level),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: masteryOnColor(pct, srsLevel: level),
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          Expanded(
            child: Text(
              spoken,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            '${pct.round()} %',
            style: theme.textTheme.bodyMedium
                ?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                )
                .merge(DesignTokens.tabularNumbers),
          ),
        ],
      ),
    );
    return Semantics(
      label: '$spoken, ${pct.round()} %',
      button: onTap != null,
      excludeSemantics: true,
      child: onTap == null
          ? row
          : InkWell(
              onTap: onTap,
              borderRadius: DesignTokens.borderRadiusCell,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: DesignTokens.touchTargetMin,
                ),
                child: row,
              ),
            ),
    );
  }
}
