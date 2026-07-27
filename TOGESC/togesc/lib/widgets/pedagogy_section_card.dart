import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_ui.dart';

/// Tarjeta de sección pedagógica (onboarding, acerca de, etc.).
class PedagogySectionCard extends StatelessWidget {
  final IconData icon;
  final Color? accentColor;
  final String title;
  final String body;
  final bool vertical;

  const PedagogySectionCard({
    super.key,
    required this.icon,
    this.accentColor,
    required this.title,
    required this.body,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accentColor ?? scheme.primaryContainer;
    final iconOnColor = color == scheme.primary
        ? scheme.onPrimary
        : color == scheme.secondary
            ? scheme.onSecondary
            : color == scheme.tertiary
                ? scheme.onTertiary
                : scheme.onPrimaryContainer;

    final iconBox = Container(
      width: vertical ? 56 : 40,
      height: vertical ? 56 : 40,
      decoration: BoxDecoration(
        color: vertical ? color : color.withValues(alpha: 0.12),
        borderRadius: DesignTokens.borderRadiusMd,
      ),
      child: Icon(
        icon,
        color: vertical ? iconOnColor : color,
        size: vertical ? 28 : 22,
      ),
    );

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: vertical ? 20 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: vertical ? 0 : DesignTokens.spacingMd,
      ),
      child: TogescCard(
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconBox,
                const SizedBox(height: DesignTokens.spacingMd),
                textBlock,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconBox,
                const SizedBox(width: DesignTokens.spacingMd),
                Expanded(child: textBlock),
              ],
            ),
    ),
    );
  }
}
