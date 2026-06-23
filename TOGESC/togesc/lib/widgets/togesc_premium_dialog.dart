import 'package:flutter/material.dart';

import '../app/design_tokens.dart';

/// Dialogo modal premium (Stitch wave2).
class TogescPremiumDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final Color accentColor;
  final bool destructive;

  const TogescPremiumDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.subtitle,
    this.icon,
    this.accentColor = DesignTokens.primaryContainer,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = destructive ? DesignTokens.error : accentColor;

    return Dialog(
      backgroundColor: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusXl,
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: DesignTokens.borderRadiusXl,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingMd),
            ],
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: destructive ? DesignTokens.error : scheme.primary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spacingLg),
            content,
            const SizedBox(height: DesignTokens.spacingLg),
            ...actions,
          ],
        ),
      ),
    );
  }
}
