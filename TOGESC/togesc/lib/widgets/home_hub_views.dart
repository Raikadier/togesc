import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'togesc_ui.dart';

/// Encabezado de sección en el hub de práctica.
class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
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
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(color: scheme.onSurface),
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

/// Hero de bienvenida en onboarding.
class OnboardingWelcomeHeader extends StatelessWidget {
  const OnboardingWelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            'TOGESC',
            style: theme.textTheme.labelLarge?.copyWith(
              color: DesignTokens.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primaryContainer.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(
            Icons.hearing_rounded,
            size: 36,
            color: scheme.primaryContainer,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Text(
          'Bienvenido al entrenador de oido absoluto',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          'Esta app usa estrategias pedagogicas comprobadas. '
          'Tres ideas clave antes de empezar:',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
