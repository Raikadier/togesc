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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.onSurfaceVariant,
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
    return TogescCard(
      color: DesignTokens.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DesignTokens.primaryContainer),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.primaryContainer, size: 22),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
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
    return TogescCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Icon(
          Icons.lock_outline_rounded,
          color: DesignTokens.secondary,
        ),
        title: const Text('Estadisticas avanzadas (Pro)'),
        subtitle: const Text(
          'Notas mas dificiles y mas faciles con TOGESC Pro.',
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: DesignTokens.onSurfaceVariant,
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
    final planLabel = isPro ? 'Pro' : 'Gratis';

    return TogescCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                DesignTokens.primaryContainer.withValues(alpha: 0.12),
            child: Icon(
              isPro ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
              color: DesignTokens.primaryContainer,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan $planLabel', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: DesignTokens.primaryContainer.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: DesignTokens.primaryContainer.withValues(alpha: 0.25),
            ),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 44,
            color: DesignTokens.primaryContainer,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingLg),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: DesignTokens.spacingMd),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: DesignTokens.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
