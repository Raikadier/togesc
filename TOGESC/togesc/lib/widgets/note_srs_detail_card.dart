import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/note_naming.dart';
import '../models/note_progress_summary.dart';
import '../models/subscription_status.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/practice_focus_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_access.dart';
import '../widgets/srs_progress_indicator.dart';
import '../widgets/togesc_ui.dart';

/// Tarjeta de progreso SRS para una nota (12 clases de altura).
class NoteSrsDetailCard extends ConsumerWidget {
  final NoteProgressSummary summary;
  final bool showAdvanced;
  final VoidCallback? onPractice;

  const NoteSrsDetailCard({
    super.key,
    required this.summary,
    required this.showAdvanced,
    this.onPractice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final naming = ref.watch(noteNamingModeProvider).valueOrNull ??
        NoteNamingMode.letter;
    final label = formatNoteLabel(summary.note, naming);

    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (summary.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.errorContainer,
                    borderRadius: DesignTokens.borderRadiusMd,
                  ),
                  child: Text(
                    'Pendiente',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: DesignTokens.incorrect,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          SrsProgressIndicator(
            note: label,
            consecutiveCorrect: summary.consecutiveCorrect,
            isLearning: summary.isLearning,
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            summary.statusLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.onSurfaceVariant,
            ),
          ),
          if (showAdvanced) ...[
            const SizedBox(height: DesignTokens.spacingMd),
            _MetricRow(
              label: 'Precision',
              value: summary.timesSeen > 0
                  ? '${summary.accuracyPercent.toStringAsFixed(0)}%'
                  : '—',
            ),
            _MetricRow(
              label: 'Intentos',
              value: '${summary.timesCorrect}/${summary.timesSeen}',
            ),
            _MetricRow(
              label: 'Peso SRS',
              value: summary.weight.toStringAsFixed(1),
            ),
            if (onPractice != null) ...[
              const SizedBox(height: DesignTokens.spacingMd),
              FilledButton.tonalIcon(
                onPressed: onPractice,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Practicar $label'),
              ),
            ],
          ] else if (onPractice != null) ...[
            const SizedBox(height: DesignTokens.spacingMd),
            OutlinedButton(
              onPressed: onPractice,
              child: const Text('Practicar (Pro)'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: DesignTokens.onSurfaceVariant),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Inicia practica enfocada en una nota (modo una nota).
void startFocusedNotePractice({
  required BuildContext context,
  required WidgetRef ref,
  required String note,
}) {
  ref.read(practiceFocusNoteProvider.notifier).state = note;
  ref.read(audioPlayerServiceProvider).captureUserGesture();
  context.push('${AppRoutes.game}/${GameMode.singleNote.id}');
}
