import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_ui.dart';

/// Encabezado de sección en el hub de práctica.
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: DesignTokens.spacingSm),
                trailing!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de modo de juego en el home.
class HomeModeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPro;
  final bool locked;

  const HomeModeOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPro = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: Semantics(
        button: true,
        label: locked ? '$title, bloqueado' : title,
        hint: subtitle,
        child: TogescCard(
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  scheme.primaryContainer.withValues(alpha: 0.12),
              child: Icon(icon, color: scheme.primaryContainer),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                ),
                if (isPro) const _ProBadge(),
              ],
            ),
            subtitle: Text(subtitle),
            trailing: Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(DesignTokens.spacingSm),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'PRO',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

