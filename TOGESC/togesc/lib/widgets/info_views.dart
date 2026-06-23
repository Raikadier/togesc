import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../providers/srs_provider.dart';
import 'togesc_premium_dialog.dart';
import 'togesc_ui.dart';

/// Encabezado de seccion en pantallas informativas (Stitch).
class InfoSectionHeader extends StatelessWidget {
  final String title;

  const InfoSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: DesignTokens.spacingMd,
        top: DesignTokens.spacingSm,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

/// Hero de Acerca de (Stitch about_premium_info).
class AboutHeroCard extends StatelessWidget {
  const AboutHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerLowest,
            scheme.surfaceContainerLow,
          ],
        ),
        borderRadius: DesignTokens.borderRadiusXl,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: DesignTokens.spacingMd),
          Text(
            'Entrenador de Oido Absoluto',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            'TOGESC (TOne GEneration SCript) es una app educativa de codigo '
            'abierto para entrenar identificacion de alturas musicales con '
            'metodos basados en evidencia. El entrenamiento ocurre en tu '
            'dispositivo; la cuenta en la nube es opcional para sincronizar '
            'progreso entre dispositivos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero de politica de privacidad (Stitch privacy_premium).
class PrivacyHeroHeader extends StatelessWidget {
  final String lastUpdated;

  const PrivacyHeroHeader({super.key, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.12),
                borderRadius: DesignTokens.borderRadiusXl,
              ),
              child: Icon(
                Icons.privacy_tip_rounded,
                color: scheme.primaryContainer,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Text(
                'Tu privacidad importa',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingXs,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Ultima actualizacion: $lastUpdated',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Enlace de navegacion en pantallas informativas.
class InfoLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const InfoLinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.06),
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            child: Icon(icon, color: scheme.primaryContainer, size: 22),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Seccion de politica en card (Stitch).
class PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const PolicySection({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      child: TogescCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialogo de confirmacion para reiniciar progreso SRS (Stitch).
Future<bool> showResetProgressDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => TogescPremiumDialog(
      icon: Icons.restart_alt_rounded,
      destructive: true,
      title: 'Reiniciar progreso?',
      subtitle:
          'Se perderan todos los datos de entrenamiento. Esta accion no se puede deshacer.',
      content: const SizedBox.shrink(),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.error,
            foregroundColor: DesignTokens.onError,
            minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusXl,
            ),
          ),
          child: const Text('Reiniciar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Ejecuta reinicio de progreso tras confirmacion del usuario.
Future<void> confirmAndResetProgress(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showResetProgressDialog(context);
  if (!confirmed || !context.mounted) return;

  await ref.read(srsSystemProvider.notifier).resetProgress();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Progreso reiniciado')),
  );
}
