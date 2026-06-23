import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_ui.dart';

/// Tarjeta de seccion pedagogica (onboarding, acerca de, etc.).
class PedagogySectionCard extends StatelessWidget {
  final IconData icon;
  final Color? accentColor;
  final String title;
  final String body;

  const PedagogySectionCard({
    super.key,
    required this.icon,
    this.accentColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accentColor ?? scheme.primaryContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      child: TogescCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
