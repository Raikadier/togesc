import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import '../models/practice_session_log.dart';
import '../providers/clock_provider.dart';
import '../providers/session_history_provider.dart';
import 'progress_v2/recent_sessions_list.dart';
import 'togesc_ui.dart';

/// Historial de sesiones de práctica guardadas localmente (Pro en v2).
///
/// Usa las mismas filas que «Últimas sesiones» de Progreso.
class SessionHistoryCard extends ConsumerWidget {
  /// Si se pasa, usa esta lista en lugar del historial completo.
  final List<PracticeSessionLog>? entries;

  /// Máximo de filas; `null` muestra todas.
  final int? limit;

  const SessionHistoryCard({super.key, this.entries, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sessionHistoryProvider);
    final now = ref.watch(clockProvider)();

    return historyAsync.when(
      data: (history) {
        final source = entries ?? history;
        if (source.isEmpty) {
          return TogescCard(
            child: Text(
              'Aún no hay sesiones guardadas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final visible = limit == null ? source : source.take(limit!).toList();

        return TogescCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${source.length} sesiones',
                      style: Theme.of(context).textTheme.titleMedium,
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
              const SizedBox(height: DesignTokens.spacingXs),
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: TogescColors.of(context).divider),
                SessionLogRow(entry: visible[i], now: now),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
