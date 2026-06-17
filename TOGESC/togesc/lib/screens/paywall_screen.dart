import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_tokens.dart';
import '../app/router.dart';
import '../config/subscription_config.dart';
import '../constants/subscription_constants.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/account_monetization_views.dart';
import '../widgets/togesc_ui.dart';

/// Pantalla de paywall (Fase 5).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({this.feature, super.key});

  final String? feature;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).paywallViewed(feature: widget.feature);
    });
  }

  Future<void> _purchase() async {
    if (ref.read(currentUserIdProvider) == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesion antes de suscribirte.'),
          ),
        );
        context.push(AppRoutes.account);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        await ref.read(subscriptionStatusProvider.notifier).openStripeCheckout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Completa el pago en el navegador. Vuelve aqui y pulsa '
                'Restaurar para actualizar tu plan.',
              ),
            ),
          );
        }
      } else {
        final ok =
            await ref.read(subscriptionStatusProvider.notifier).purchasePro();
        if (mounted && ok) context.pop(true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startTrial() async {
    if (ref.read(currentUserIdProvider) == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crea una cuenta antes de iniciar la prueba.'),
          ),
        );
        context.push(AppRoutes.account);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(subscriptionStatusProvider.notifier).startTrial();
      await ref.read(analyticsServiceProvider).subscriptionTrialStarted();
      if (mounted) context.pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final ok =
          await ref.read(subscriptionStatusProvider.notifier).restorePurchases();
      if (mounted) {
        if (ok) {
          context.pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontro suscripcion activa.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;

    return TogescScaffold(
      title: 'TOGESC Pro',
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          PaywallHero(
            title: feature != null ? 'Desbloquea $feature' : 'Pasa a TOGESC Pro',
            subtitle:
                'Entrena con todos los modos, estadisticas avanzadas y '
                'sincronizacion entre dispositivos.',
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const ProFeatureRow(
            icon: Icons.piano_rounded,
            text: 'Acordes, aleatorio y modo velocidad',
          ),
          const ProFeatureRow(
            icon: Icons.sync_rounded,
            text: 'Sincronizacion SRS en la nube',
          ),
          const ProFeatureRow(
            icon: Icons.analytics_rounded,
            text: 'Estadisticas avanzadas',
          ),
          const SizedBox(height: DesignTokens.spacingLg * 2),
          if (SubscriptionConfig.isActive) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _purchase,
                child: Text(kIsWeb ? 'Suscribirme (Stripe)' : 'Suscribirme'),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _startTrial,
                child: Text(
                  'Probar ${SubscriptionConstants.trialDays} dias gratis',
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _restore,
                child: const Text('Restaurar compras'),
              ),
            ),
          ] else ...[
            Text(
              'Monetizacion no activa en este build. Todos los modos estan '
              'disponibles.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
