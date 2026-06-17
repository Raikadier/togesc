import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_tokens.dart';
import '../providers/srs_provider.dart';
import 'togesc_ui.dart';

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
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: TogescCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: DesignTokens.primaryContainer),
          title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          subtitle: Text(subtitle),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: DesignTokens.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Seccion de texto en politica de privacidad.
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

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialogo de confirmacion para reiniciar progreso SRS.
Future<bool> showResetProgressDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reiniciar progreso?'),
      content: const Text(
        'Se perderan todos los datos de entrenamiento. Esta accion no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: DesignTokens.error,
            foregroundColor: DesignTokens.onError,
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
