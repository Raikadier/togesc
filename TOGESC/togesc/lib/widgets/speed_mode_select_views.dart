import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_ui.dart';

/// Hero del selector de modo velocidad (Stitch).
class SpeedModeSelectHero extends StatelessWidget {
  const SpeedModeSelectHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingXs,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.speedContainer.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.2 : 1,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: DesignTokens.speedAccent.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: DesignTokens.speedAccent,
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'MODO ENTRENAMIENTO',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: DesignTokens.speedAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          'Velocidad: elige tu desafio',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          'Lleva tu oido al siguiente nivel con rafagas de notas en tiempo real.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        TogescCard(
          color: scheme.surfaceContainerLowest,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DesignTokens.speedContainer.withValues(
                    alpha: scheme.brightness == Brightness.dark ? 0.25 : 1,
                  ),
                  borderRadius: DesignTokens.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: DesignTokens.speedAccent,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTA IMPORTANTE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: DesignTokens.speedAccent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      'El tiempo limite disminuira con cada respuesta correcta. '
                      'Manten la concentracion al maximo.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
