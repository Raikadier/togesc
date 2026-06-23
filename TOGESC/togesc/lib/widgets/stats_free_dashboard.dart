import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../widgets/togesc_shell.dart';
import 'togesc_ui.dart';

/// Encabezado del dashboard de estadisticas (Free / Pro).
class StatsDashboardHeader extends StatelessWidget {
  final bool isPro;

  const StatsDashboardHeader({super.key, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPro)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingXs,
            ),
            decoration: BoxDecoration(
              gradient: DesignTokens.proGradient,
              borderRadius: DesignTokens.borderRadiusXl,
            ),
            child: Text(
              'ESTADISTICAS PRO',
              style: theme.textTheme.labelMedium?.copyWith(
                color: DesignTokens.onPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          )
        else
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
              'PLAN GRATUITO',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          isPro ? 'Estadisticas Pro' : 'Estadisticas',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          isPro
              ? 'Analisis de rendimiento y retencion cognitiva.'
              : 'Resumen basico de tu entrenamiento. Desbloquea Pro para radar, '
                  'notas dificiles y exportacion.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Seccion bloqueada de estadisticas avanzadas (Stitch free mode).
class StatsFreeAdvancedLockSection extends StatelessWidget {
  final VoidCallback onUnlock;

  const StatsFreeAdvancedLockSection({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      children: [
        Opacity(
          opacity: 0.35,
          child: IgnorePointer(
            child: TogescCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vista previa Pro',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: DesignTokens.spacingMd),
                  Container(
                    height: 160,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: DesignTokens.borderRadiusXl,
                    ),
                    child: Icon(
                      Icons.radar_rounded,
                      size: 96,
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(
                    'Radar de precision, notas dificiles y export CSV',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: scheme.surfaceContainerLowest.withValues(alpha: 0.72),
            borderRadius: DesignTokens.borderRadiusXl,
            child: InkWell(
              onTap: onUnlock,
              borderRadius: DesignTokens.borderRadiusXl,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: DesignTokens.proGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: DesignTokens.onPrimary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),
                    Text(
                      'Estadisticas avanzadas (Pro)',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingSm),
                    Text(
                      'Notas mas dificiles, mayor dominio, radar 12 notas '
                      'y exportacion CSV.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingLg),
                    TogescProButton(
                      label: 'Desbloquear con Pro',
                      onPressed: onUnlock,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Card compacta de upsell Pro en stats free.
class StatsFreeProUpsellCard extends StatelessWidget {
  final VoidCallback onTap;

  const StatsFreeProUpsellCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TogescCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pasa a Pro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Radar, analisis por nota y sync en la nube.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
