import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../app/togesc_colors.dart';
import 'togesc_ui.dart';

/// Sección Pro bloqueada de Progreso v2 (D7): el usuario gratis ve la
/// rejilla de 12 notas; la evolución, el historial completo y la
/// exportación quedan tras el candado.
class StatsFreeProUpsellCard extends StatelessWidget {
  final VoidCallback onTap;

  const StatsFreeProUpsellCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Evolución e historial completo, función Pro. Toca para ver Pro.',
      excludeSemantics: true,
      child: TogescCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DesignTokens.pro.withValues(alpha: 0.12),
                borderRadius: DesignTokens.borderRadiusCell,
              ),
              child: Icon(
                Icons.lock_rounded,
                color: TogescColors.of(context).proAccent,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolución e historial · Pro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Gráficas por periodo, historial completo de sesiones '
                    'y exportación CSV.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
