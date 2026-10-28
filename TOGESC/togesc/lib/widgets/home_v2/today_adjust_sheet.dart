import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../constants/note_naming.dart';
import '../../models/note_progress_summary.dart';
import '../../models/practice_session_log.dart' show chromaticNotes;
import '../../models/practice_session_preferences.dart';
import '../../providers/app_preferences_provider.dart';
import '../../providers/clock_provider.dart';
import '../../providers/practice_focus_provider.dart';
import '../../providers/practice_session_preferences_provider.dart';
import '../../providers/srs_provider.dart';
import '../../providers/today_session_provider.dart';
import '../../utils/srs_level.dart';
import '../progress_v2/progress_metrics.dart';

/// Duraciones de la hoja (SPEC v2.1 §2.1): 6 · 3 min, 12 · 6 min, 20 · 10 min.
const todayAdjustRoundGoals = [
  SessionRoundGoal.six,
  SessionRoundGoal.twelve,
  SessionRoundGoal.twenty,
];

/// Mínimo de notas foco elegidas a mano.
const int minTodayFocusNotes = 1;

/// Abre la hoja «Ajustar la sesión de hoy». Al guardar:
/// - la duración pasa a la meta de rondas (`practiceSessionPreferences`,
///   persistida; es la misma meta de Ajustes);
/// - las notas foco quedan fijadas para hoy (`todayFocusOverrideProvider`).
Future<void> showTodayAdjustSheet(BuildContext context, WidgetRef ref) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const TodayAdjustSheet(),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Sesión de hoy actualizada')),
    );
  }
}

class TodayAdjustSheet extends ConsumerStatefulWidget {
  const TodayAdjustSheet({super.key});

  @override
  ConsumerState<TodayAdjustSheet> createState() => _TodayAdjustSheetState();
}

class _TodayAdjustSheetState extends ConsumerState<TodayAdjustSheet> {
  late SessionRoundGoal? _goal;
  late List<String> _focus;
  bool _limitHit = false;

  @override
  void initState() {
    super.initState();
    final plan = ref.read(todaySessionPlanProvider);
    _goal = todayAdjustRoundGoals.contains(plan.roundGoal)
        ? plan.roundGoal
        : null;
    _focus = [...plan.focusNoteNames];
  }

  void _toggle(String note) {
    setState(() {
      _limitHit = false;
      if (_focus.contains(note)) {
        if (_focus.length > minTodayFocusNotes) _focus.remove(note);
      } else if (_focus.length < maxPracticeFocusNotes) {
        _focus.add(note);
      } else {
        _limitHit = true;
      }
    });
  }

  Future<void> _save() async {
    final goal = _goal;
    if (goal != null) {
      await ref
          .read(practiceSessionPreferencesProvider.notifier)
          .setRoundGoal(goal);
    }
    if (_focus.isNotEmpty) {
      ref.read(todayFocusOverrideProvider.notifier).state = TodayFocusOverride(
        day: ref.read(clockProvider)(),
        notes: List.unmodifiable(_focus),
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  String _goalLabel(SessionRoundGoal goal) {
    final minutes = goal.estimatedMinutes;
    if (goal == SessionRoundGoal.six) return '6 rondas · $minutes min';
    return '${goal.rounds} · $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = TogescColors.of(context);
    final namingMode =
        ref.watch(noteNamingModeProvider).valueOrNull ?? NoteNamingMode.letter;
    final learningThreshold = ref.watch(srsLearningThresholdProvider);
    final summaries = {
      for (final s in ref.watch(noteProgressSummariesProvider)) s.note: s,
    };

    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.textPrimary,
    );

    return Padding(
      key: const ValueKey('today-adjust-sheet'),
      padding: EdgeInsets.fromLTRB(
        DesignTokens.marginMobile,
        0,
        DesignTokens.marginMobile,
        DesignTokens.marginMobile + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Ajustar la sesión de hoy',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            Text('Duración', style: labelStyle),
            const SizedBox(height: DesignTokens.spacingSm),
            SegmentedButton<SessionRoundGoal>(
              key: const ValueKey('today-adjust-duration'),
              segments: [
                for (final goal in todayAdjustRoundGoals)
                  ButtonSegment(
                    value: goal,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_goalLabel(goal)),
                    ),
                    tooltip:
                        '${goal.rounds} rondas, unos ${goal.estimatedMinutes} '
                        'minutos estimados',
                  ),
              ],
              selected: {?_goal},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                if (value.isEmpty) return;
                setState(() => _goal = value.first);
              },
            ),
            const SizedBox(height: DesignTokens.spacingLg + 4),
            Text.rich(
              TextSpan(
                text: 'Notas foco ',
                children: [
                  TextSpan(
                    text: '(elige de $minTodayFocusNotes a '
                        '$maxPracticeFocusNotes)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              style: labelStyle,
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Wrap(
              spacing: DesignTokens.spacingSm,
              runSpacing: DesignTokens.spacingSm,
              children: [
                for (final note in chromaticNotes)
                  _NoteChip(
                    note: note,
                    summary: summaries[note],
                    namingMode: namingMode,
                    learningThreshold: learningThreshold,
                    selected: _focus.contains(note),
                    onTap: () => _toggle(note),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            Semantics(
              liveRegion: true,
              child: Text(
                _limitHit
                    ? 'Máximo $maxPracticeFocusNotes notas foco. Quita una '
                        'para elegir otra.'
                    : 'Las notas foco suenan más a menudo; el resto mantiene '
                        'el repaso SRS normal.',
                key: const ValueKey('today-adjust-hint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _limitHit
                      ? theme.colorScheme.error
                      : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg + 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('today-adjust-cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        DesignTokens.touchTargetMin,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('today-adjust-save'),
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        DesignTokens.touchTargetMin,
                      ),
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({
    required this.note,
    required this.summary,
    required this.namingMode,
    required this.learningThreshold,
    required this.selected,
    required this.onTap,
  });

  final String note;
  final NoteProgressSummary? summary;
  final NoteNamingMode namingMode;
  final int learningThreshold;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    final s = summary;
    final seen = s != null && s.timesSeen > 0;
    final label = formatNoteLabel(note, namingMode);
    final swatch = seen
        ? masteryColor(
            s.accuracyPercent,
            srsLevel: srsLevelForSummary(
              s,
              learningThreshold: learningThreshold,
            ),
          )
        : colors.muted;
    final spoken = spokenNoteName(label);
    final semantics =
        seen ? '$spoken, ${s.accuracyPercent.round()} %' : '$spoken, sin datos';

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      button: true,
      toggled: selected,
      onTap: onTap,
      child: FilterChip(
        key: ValueKey('today-adjust-note-$note'),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: colors.tile,
        selectedColor: DesignTokens.hero,
        side: BorderSide(
          color: selected ? DesignTokens.hero : colors.cardBorder,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusPill,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: colors.cardBorder, width: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? DesignTokens.onHero : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
