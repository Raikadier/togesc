import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../config/subscription_config.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

/// Gestion de suscripcion Pro.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(subscriptionStatusProvider.notifier).refresh(),
    );
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final ok =
          await ref.read(subscriptionStatusProvider.notifier).restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Suscripcion restaurada.' : 'No hay suscripcion activa.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manageBilling() async {
    if (kIsWeb) {
      await ref.read(subscriptionStatusProvider.notifier).openStripePortal();
    } else {
      await _restore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final signedIn = ref.watch(currentUserIdProvider) != null;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Suscripcion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!SubscriptionConfig.isActive) ...[
            const Text(
              'Monetizacion desactivada en este build.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Activa MONETIZATION_ENABLED y las claves de tienda en '
              'produccion para habilitar planes Free/Pro.',
              style: TextStyle(color: muted),
            ),
          ] else ...[
            statusAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Error al cargar suscripcion.'),
              data: (status) {
                final planLabel = status.isPro ? 'Pro' : 'Gratis';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        status.isPro
                            ? Icons.workspace_premium
                            : Icons.person_outline,
                        color: status.isPro ? Colors.amber : null,
                      ),
                      title: Text('Plan $planLabel'),
                      subtitle: Text(
                        status.isTrialing
                            ? 'Periodo de prueba activo'
                            : status.isPro
                                ? 'Acceso completo'
                                : 'Modos basicos y SRS local',
                      ),
                    ),
                    if (!status.isPro) ...[
                      FilledButton(
                        onPressed: () => context.push(AppRoutes.paywall),
                        child: const Text('Ver planes Pro'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (status.isPro && signedIn) ...[
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _manageBilling,
                        icon: const Icon(Icons.payment),
                        label: Text(
                          kIsWeb ? 'Gestionar pago (Stripe)' : 'Restaurar compras',
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (!signedIn)
              Text(
                'Inicia sesion para sincronizar tu suscripcion entre dispositivos.',
                style: TextStyle(color: muted),
              ),
          ],
        ],
      ),
    );
  }
}
