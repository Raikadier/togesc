import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../providers/session_history_provider.dart';
import 'togesc_ui.dart';

/// Ultimas sesiones de practica guardadas localmente (Fase 7C-2).
class SessionHistoryCard extends ConsumerWidget {
  const SessionHistoryCard({super.key});

  String _formatWhen(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final hh = when.hour.toString().padLeft(2, '0');
    final mm = when.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';

    if (day == today) return 'Hoy · $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Ayer · $time';
    }
    return '${when.day}/${when.month} · $time';
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy >= 80) return DesignTokens.correct;
    if (accuracy >= 50) return DesignTokens.selection;
    return DesignTokens.incorrect;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sessionHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) return const SizedBox.shrink();

        final recent = history.take(8).toList();

        return TogescCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Historial reciente',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(sessionHistoryProvider.notifier).clear();
                    },
                    child: const Text('Borrar'),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              ...recent.map((entry) {
                final accuracy = entry.accuracyPercent.round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.modeLabel,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${entry.roundsCompleted} rondas · '
                              '${entry.correctRounds} aciertos',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$accuracy%',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: _accuracyColor(accuracy.toDouble()),
                                ),
                          ),
                          Text(
                            _formatWhen(entry.endedAt),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
