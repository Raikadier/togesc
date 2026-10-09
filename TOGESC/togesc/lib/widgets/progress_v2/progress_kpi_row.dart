import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import 'progress_metrics.dart';

/// Fila de 3 KPI de Progreso v2: latencia media (aprox.), intentos y
/// pendientes. «Pendientes» va en la card `hero` (#2A0640).
class ProgressKpiRow extends StatelessWidget {
  const ProgressKpiRow({
    super.key,
    required this.meanLatencySec,
    required this.attempts,
    required this.pending,
    this.onReviewPending,
  });

  /// Latencia media aproximada en segundos; `null` si no hay datos.
  final double? meanLatencySec;
  final int attempts;
  final int pending;

  /// Abre un repaso de las notas pendientes (solo si [pending] > 0).
  final VoidCallback? onReviewPending;

  @override
  Widget build(BuildContext context) {
    final latency = meanLatencySec;
    final cards = [
      _KpiCard(
        label: 'Latencia media',
        caption: 'aprox.',
        value: latency == null ? '—' : '${latency.toStringAsFixed(1)}s',
        semanticsLabel: latency == null
            ? 'Latencia media: sin datos'
            : 'Latencia media aproximada: '
                '${latency.toStringAsFixed(1)} segundos',
      ),
      _KpiCard(
        label: 'Intentos',
        caption: 'notas escuchadas',
        value: formatThousands(attempts),
        semanticsLabel: 'Intentos: $attempts notas escuchadas',
      ),
      _KpiCard(
        label: 'Pendientes',
        caption: pending > 0 ? 'repasar ahora' : 'al día',
        value: '$pending',
        hero: true,
        semanticsLabel: pending > 0
            ? 'Pendientes: $pending notas. Toca para repasar.'
            : 'Pendientes: ninguna nota',
        onTap: pending > 0 ? onReviewPending : null,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: DesignTokens.spacingSm),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.caption,
    required this.value,
    required this.semanticsLabel,
    this.hero = false,
    this.onTap,
  });

  final String label;
  final String caption;
  final String value;
  final String semanticsLabel;
  final bool hero;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = hero ? DesignTokens.hero : scheme.surfaceContainerLowest;
    final labelColor =
        hero ? DesignTokens.onHeroAccent : scheme.onSurfaceVariant;
    final valueColor = hero ? DesignTokens.onHero : scheme.onSurface;

    final content = Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 2,
            style: theme.textTheme.labelMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.merge(DesignTokens.tabularNumbers)
                  .copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: labelColor),
          ),
        ],
      ),
    );

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusCard,
          side: hero
              ? BorderSide.none
              : const BorderSide(color: DesignTokens.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
