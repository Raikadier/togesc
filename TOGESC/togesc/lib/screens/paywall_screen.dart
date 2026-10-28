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
import '../widgets/paywall_views.dart';

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
      ref
          .read(analyticsServiceProvider)
          .paywallViewed(
            feature: SubscriptionConstants.paywallFeatureTitle(widget.feature),
          );
    });
  }

  Future<void> _purchase() async {
    if (ref.read(currentUserIdProvider) == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión antes de suscribirte.')),
        );
        context.push(AppRoutes.account);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        await ref
            .read(subscriptionStatusProvider.notifier)
            .openStripeCheckout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Completa el pago en el navegador. Vuelve aquí y pulsa '
                'Restaurar para actualizar tu plan.',
              ),
            ),
          );
        }
      } else {
        final ok = await ref
            .read(subscriptionStatusProvider.notifier)
            .purchasePro();
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
      final ok = await ref
          .read(subscriptionStatusProvider.notifier)
          .restorePurchases();
      if (mounted) {
        if (ok) {
          context.pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró suscripción activa.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PT-10: solo se muestran funciones Pro conocidas (allowlist).
    final feature = SubscriptionConstants.paywallFeatureTitle(widget.feature);

    // v2.1 (SPEC §2.6): fondo `hero` a pantalla completa con el pitch y,
    // al lado (o debajo en móvil), el panel «Gratis o Pro».
    return Scaffold(
      backgroundColor: DesignTokens.hero,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final margin = wide
                ? DesignTokens.marginDesktop
                : DesignTokens.marginMobile;
            final pitch = PaywallPitch(
              feature: feature,
              subtitle:
                  'Entrena con todos los modos, estadísticas avanzadas y '
                  'sincronización entre dispositivos.',
            );
            final panel = _buildComparePanel(context);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(margin, 0, margin, margin),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 64,
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: Text(
                                'TOGESC',
                                style: DesignTokens.logo.copyWith(
                                  color: DesignTokens.onHeroAccent,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Cerrar',
                              color: DesignTokens.onHero,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => context.pop(),
                            ),
                          ],
                        ),
                      ),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: pitch),
                            const SizedBox(width: DesignTokens.spacingLg * 2),
                            Expanded(child: panel),
                          ],
                        )
                      else ...[
                        pitch,
                        const SizedBox(height: DesignTokens.spacingLg),
                        panel,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildComparePanel(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fine = Text(
      'Cancela cuando quieras. El progreso SRS local siempre se conserva.',
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(color: scheme.outline),
    );
    const trialDays = SubscriptionConstants.trialDays;

    return Container(
      key: const ValueKey('paywall-panel'),
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: DesignTokens.borderRadiusHero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Gratis o Pro',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          const PaywallCompareTable(),
          const SizedBox(height: DesignTokens.spacingLg),
          if (SubscriptionConfig.isActive) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: DesignTokens.pro,
                ),
                const SizedBox(width: DesignTokens.spacingSm),
                Expanded(
                  child: Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(
                          text: '$trialDays días gratis. ',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text:
                              'El precio se muestra en la tienda antes de '
                              'confirmar.',
                        ),
                      ],
                    ),
                    key: const ValueKey('paywall-trial-note'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            FilledButton(
              key: const ValueKey('paywall-cta'),
              onPressed: _busy ? null : _startTrial,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(DesignTokens.ctaHeight),
                backgroundColor: DesignTokens.ctaAmber,
                foregroundColor: DesignTokens.onCtaAmber,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: DesignTokens.borderRadiusCta,
                ),
              ),
              child: const Text('Probar $trialDays días gratis'),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            OutlinedButton(
              key: const ValueKey('paywall-subscribe'),
              onPressed: _busy ? null : _purchase,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
              ),
              child: Text(kIsWeb ? 'Suscribirme (Stripe)' : 'Suscribirme'),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            fine,
            Center(
              child: TextButton(
                key: const ValueKey('paywall-restore'),
                onPressed: _busy ? null : _restore,
                child: const Text('Restaurar compras'),
              ),
            ),
          ] else ...[
            Text(
              'Monetización no activa en este build. Todos los modos están '
              'disponibles.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            FilledButton(
              onPressed: () => context.pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(DesignTokens.touchTargetMin),
              ),
              child: const Text('Continuar'),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            fine,
          ],
        ],
      ),
    );
  }
}
