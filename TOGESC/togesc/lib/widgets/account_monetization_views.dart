import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_ui.dart';

/// Titulo de seccion en formularios de cuenta.
class AccountSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AccountSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Aviso informativo en cuenta (verificacion, Pro, sync pendiente).
class AccountInfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AccountInfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TogescCard(
      color: scheme.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Card bloqueada de funcion Pro (estadisticas avanzadas).
class ProLockedFeatureCard extends StatelessWidget {
  final VoidCallback onTap;

  const ProLockedFeatureCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TogescCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Icon(
          Icons.lock_outline_rounded,
          color: scheme.secondary,
        ),
        title: const Text('Estadísticas avanzadas (Pro)'),
        subtitle: const Text(
          'Notas más difíciles y más fáciles con TOGESC Pro.',
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Estado del plan en pantalla de suscripcion.
class SubscriptionPlanCard extends StatelessWidget {
  final bool isPro;
  final String subtitle;

  const SubscriptionPlanCard({
    super.key,
    required this.isPro,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final planLabel = isPro ? 'Pro' : 'Gratis';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan actual'.toUpperCase(),
          style: DesignTokens.overline.copyWith(
            color: isPro ? DesignTokens.onHeroAccent : scheme.onSurfaceVariant,
          ),
        ),
        Text(
          planLabel,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: isPro ? DesignTokens.onHero : scheme.primary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isPro ? DesignTokens.onHero : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    // Plan Pro en la card `hero` v2 (#2A0640), igual en claro y oscuro:
    // texto `onHero` 17,5:1 y overline `onHeroAccent` 8,5:1. Antes usaba
    // `primaryContainer`/`onPrimary`, que en oscuro quedaba morado sobre
    // morado.
    if (isPro) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        decoration: BoxDecoration(
          color: DesignTokens.hero,
          borderRadius: DesignTokens.borderRadiusCard,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: DesignTokens.onHero.withValues(alpha: 0.12),
                borderRadius: DesignTokens.borderRadiusCell,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: DesignTokens.onHeroAccent,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(child: content),
          ],
        ),
      );
    }

    return TogescCard(child: content);
  }
}
