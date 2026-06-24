import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/sync_provider.dart';
import '../services/account_service.dart';
import '../services/progress_export_download.dart';
import '../services/user_data_export_service.dart';
import 'account_monetization_views.dart';
import 'togesc_ui.dart';

/// Exportacion JSON y eliminacion de cuenta (Fase 7E-1).
class AccountDataSection extends ConsumerWidget {
  const AccountDataSection({
    super.key,
    required this.busy,
    required this.onBusyChanged,
    required this.onMessage,
  });

  final bool busy;
  final ValueChanged<bool> onBusyChanged;
  final ValueChanged<String?> onMessage;

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final srs = ref.read(srsSystemProvider).valueOrNull;
    if (srs == null) {
      onMessage('No hay progreso para exportar.');
      return;
    }

    final prefs = await ref.read(appPreferencesProvider.future);
    final json = UserDataExportService.buildJson(srs: srs, prefs: prefs);
    const filename = 'togesc_datos.json';

    if (kIsWeb) {
      downloadCsvWeb(json, filename: filename);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descarga JSON iniciada')),
        );
      }
    } else {
      await Clipboard.setData(ClipboardData(text: json));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos copiados al portapapeles')),
        );
      }
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    SupabaseClient client,
    String email,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          'Se borraran tu cuenta ($email) y el progreso sincronizado '
          'en la nube. El progreso local en este dispositivo se conserva. '
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.error,
              foregroundColor: DesignTokens.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    onBusyChanged(true);
    onMessage(null);

    try {
      await AccountService.deleteOwnAccount(client);
      ref.invalidate(progressRepositoryProvider);
      ref.invalidate(syncDiagnosticsProvider);
      ref.invalidate(syncPendingProvider);
      ref.invalidate(subscriptionStatusProvider);
      if (context.mounted) {
        onMessage('Cuenta eliminada. Tu progreso local se conserva.');
      }
    } on AuthException catch (e) {
      onMessage(e.message);
    } catch (_) {
      onMessage(
        'No se pudo eliminar la cuenta. Comprueba la conexion o contacta '
        'con soporte.',
      );
    } finally {
      onBusyChanged(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseClientProvider);
    final signedIn = ref.watch(currentUserEmailProvider) != null;

    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AccountSectionTitle(
            title: 'Tus datos',
            subtitle:
                'Exporta una copia portable o elimina tu cuenta en la nube.',
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          OutlinedButton.icon(
            onPressed: busy ? null : () => _exportJson(context, ref),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Exportar datos (JSON)'),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          OutlinedButton.icon(
            onPressed: busy ? null : () => context.push(AppRoutes.privacy),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Politica de privacidad'),
          ),
          if (signedIn && client != null) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => _deleteAccount(
                        context,
                        ref,
                        client,
                        ref.read(currentUserEmailProvider)!,
                      ),
              icon: Icon(Icons.delete_forever_outlined, color: DesignTokens.error),
              label: Text(
                'Eliminar cuenta',
                style: TextStyle(color: DesignTokens.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
