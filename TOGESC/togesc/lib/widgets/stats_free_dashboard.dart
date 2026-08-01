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
        Text(
          isPro ? 'Estadísticas Pro' : 'Estadísticas',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: scheme.primary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          isPro
              ? 'Análisis de rendimiento y retención cognitiva.'
              : 'Resumen básico de tu entrenamiento. Desbloquea Pro para radar, '
                  'notas difíciles y exportación.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (isPro) ...[
          const SizedBox(height: DesignTokens.spacingMd),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: DesignTokens.borderRadiusMd,
              ),
              child: Text(
                'Pro',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
                    'Radar de precisión, notas difíciles y export CSV',
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
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),
                    Text(
                      'Estadísticas avanzadas (Pro)',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingSm),
                    Text(
                      'Notas más difíciles, mayor dominio, radar 12 notas '
                      'y exportación CSV.',
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
                  'Radar, análisis por nota y sync en la nube.',
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
