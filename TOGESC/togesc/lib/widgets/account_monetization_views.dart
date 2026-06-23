import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import 'game_session_views.dart';
import 'togesc_ui.dart';

/// Supabase no configurado — modo offline.
class AccountOfflineView extends StatelessWidget {
  const AccountOfflineView({super.key});

  @override
  Widget build(BuildContext context) {
    return GameSessionPhaseLayout(
      icon: Icons.cloud_off_rounded,
      title: 'Sincronizacion no disponible',
      subtitle:
          'Este despliegue no tiene Supabase configurado. Puedes entrenar '
          'con normalidad: el progreso se guarda solo en tu dispositivo.',
    );
  }
}

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
          Icon(icon, color: scheme.primaryContainer),
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

/// Fila de beneficio Pro en paywall.
class ProFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const ProFeatureRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.12),
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            child: Icon(icon, color: scheme.primaryContainer, size: 20),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: DesignTokens.correct,
            size: 20,
          ),
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
        title: const Text('Estadisticas avanzadas (Pro)'),
        subtitle: const Text(
          'Notas mas dificiles y mas faciles con TOGESC Pro.',
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Metrica en dashboard de estadisticas.
class StatsMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatsMetricRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

/// Seccion de notas (dificiles / faciles).
class StatsNotesSection extends StatelessWidget {
  final String title;
  final List<String> notes;
  final Color color;
  final IconData icon;

  const StatsNotesSection({
    super.key,
    required this.title,
    required this.notes,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: DesignTokens.spacingSm),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Wrap(
            spacing: DesignTokens.spacingSm,
            children: notes
                .map(
                  (note) => Chip(
                    label: Text(note, style: TextStyle(color: color)),
                    backgroundColor: color.withValues(alpha: 0.1),
                    side: BorderSide(color: color.withValues(alpha: 0.35)),
                  ),
                )
                .toList(),
          ),
        ],
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
          'PLAN ACTUAL',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isPro
                ? scheme.onPrimary.withValues(alpha: 0.85)
                : scheme.outline,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          planLabel,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isPro ? scheme.onPrimary : scheme.primary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isPro
                ? scheme.onPrimary.withValues(alpha: 0.85)
                : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (isPro) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        decoration: BoxDecoration(
          gradient: DesignTokens.proGradient,
          borderRadius: DesignTokens.borderRadiusXl,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: DesignTokens.borderRadiusXl,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: DesignTokens.onPrimary,
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

/// Hero del paywall Pro.
class PaywallHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const PaywallHero({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
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
            'TOGESC PRO',
            style: theme.textTheme.labelMedium?.copyWith(
              color: DesignTokens.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: DesignTokens.proGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: scheme.primaryContainer.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 44,
            color: DesignTokens.onPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
