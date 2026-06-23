import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../config/subscription_config.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/account_monetization_views.dart';
import '../widgets/togesc_ui.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          Text(
            'Suscripcion Pro',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          if (!SubscriptionConfig.isActive) ...[
            TogescCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monetizacion desactivada en este build.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(
                    'Activa MONETIZATION_ENABLED y las claves de tienda en '
                    'produccion para habilitar planes Free/Pro.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ] else
            statusAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Error al cargar suscripcion.'),
              data: (status) {
                final subtitle = status.isTrialing
                    ? 'Periodo de prueba activo'
                    : status.isPro
                        ? 'Acceso completo'
                        : 'Modos basicos y SRS local';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SubscriptionPlanCard(
                      isPro: status.isPro,
                      subtitle: subtitle,
                    ),
                    const SizedBox(height: DesignTokens.spacingLg),
                    if (!status.isPro)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.push(AppRoutes.paywall),
                          child: const Text('Ver planes Pro'),
                        ),
                      ),
                    if (status.isPro && signedIn) ...[
                      const SizedBox(height: DesignTokens.spacingSm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _manageBilling,
                          icon: const Icon(Icons.payment_rounded),
                          label: Text(
                            kIsWeb
                                ? 'Gestionar pago (Stripe)'
                                : 'Restaurar compras',
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          if (SubscriptionConfig.isActive && !signedIn) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              'Inicia sesion para sincronizar tu suscripcion entre dispositivos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
