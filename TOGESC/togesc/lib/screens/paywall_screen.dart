import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../config/subscription_config.dart';
import '../constants/subscription_constants.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TOGESC Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.workspace_premium, size: 64, color: primary),
          const SizedBox(height: 16),
          Text(
            feature != null ? 'Desbloquea $feature' : 'Pasa a TOGESC Pro',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Entrena con todos los modos, estadisticas avanzadas y '
            'sincronizacion entre dispositivos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _FeatureRow(
            icon: Icons.piano,
            text: 'Acordes, aleatorio y modo velocidad',
          ),
          _FeatureRow(
            icon: Icons.sync,
            text: 'Sincronizacion SRS en la nube',
          ),
          _FeatureRow(
            icon: Icons.analytics,
            text: 'Estadisticas avanzadas',
          ),
          const SizedBox(height: 32),
          if (SubscriptionConfig.isActive) ...[
            FilledButton(
              onPressed: _busy ? null : _purchase,
              child: Text(kIsWeb ? 'Suscribirme (Stripe)' : 'Suscribirme'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _startTrial,
              child: Text(
                'Probar ${SubscriptionConstants.trialDays} dias gratis',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _restore,
              child: const Text('Restaurar compras'),
            ),
          ] else ...[
            const Text(
              'Monetizacion no activa en este build. Todos los modos estan '
              'disponibles.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Continuar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
