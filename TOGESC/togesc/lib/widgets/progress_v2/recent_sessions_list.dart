import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../models/practice_session_log.dart';
import '../../utils/relative_time.dart';

/// Fila de sesión de Progreso v2: modo, «N rondas · M aciertos», % en una
/// píldora del color de dominio y fecha relativa.
class SessionLogRow extends StatelessWidget {
  const SessionLogRow({super.key, required this.entry, required this.now});

  final PracticeSessionLog entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pct = entry.accuracyPercent;
    final rounded = pct.round();
    final when = formatRelativeTimeEs(entry.endedAt, now: now);
    final detail =
        '${entry.roundsCompleted} rondas · ${entry.correctRounds} aciertos';

    return Semantics(
      label: '${entry.modeLabel}, $detail, $rounded %, $when',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.modeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall
                        ?.merge(DesignTokens.tabularNumbers)
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spacingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: masteryColor(pct),
                    borderRadius: DesignTokens.borderRadiusPill,
                  ),
                  child: Text(
                    '$rounded%',
                    style: theme.textTheme.labelLarge
                        ?.merge(DesignTokens.tabularNumbers)
                        .copyWith(
                          color: masteryOnColor(pct),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  when,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

/// «Últimas sesiones» (3 filas) con el acceso a «Historial».
///
/// El historial completo es Pro (D7): sin acceso, el botón lleva candado y
/// [onOpenHistory] debe abrir el paywall.
class RecentSessionsList extends StatelessWidget {
  const RecentSessionsList({
    super.key,
    required this.entries,
    required this.now,
    required this.historyUnlocked,
    required this.onOpenHistory,
    this.maxRows = 3,
  });

  final List<PracticeSessionLog> entries;
  final DateTime now;
  final bool historyUnlocked;
  final VoidCallback onOpenHistory;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recent = entries.take(maxRows).toList();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: DesignTokens.borderRadiusCard,
        border: Border.all(color: DesignTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Últimas sesiones',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Semantics(
                label: historyUnlocked
                    ? 'Historial completo'
                    : 'Historial completo, función Pro bloqueada',
                button: true,
                excludeSemantics: true,
                child: TextButton.icon(
                  key: const Key('progress-history-button'),
                  onPressed: onOpenHistory,
                  icon: Icon(
                    historyUnlocked
                        ? Icons.history_rounded
                        : Icons.lock_rounded,
                    size: 18,
                  ),
                  label: const Text('Historial'),
                ),
              ),
            ],
          ),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
              child: Text(
                'Tus sesiones aparecerán aquí al terminar la primera.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var i = 0; i < recent.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: DesignTokens.divider),
              SessionLogRow(entry: recent[i], now: now),
            ],
        ],
      ),
    );
  }
}
