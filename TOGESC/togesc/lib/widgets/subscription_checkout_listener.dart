import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/subscription_config.dart';
import '../providers/subscription_provider.dart';

/// Detecta retorno de Stripe Checkout en web (?checkout=success|cancel).
class SubscriptionCheckoutListener extends ConsumerStatefulWidget {
  const SubscriptionCheckoutListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SubscriptionCheckoutListener> createState() =>
      _SubscriptionCheckoutListenerState();
}

class _SubscriptionCheckoutListenerState
    extends ConsumerState<SubscriptionCheckoutListener> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && SubscriptionConfig.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleReturn());
    }
  }

  Future<void> _handleReturn() async {
    if (_handled || !mounted) return;

    final checkout = Uri.base.queryParameters['checkout'];
    if (checkout == null) return;

    _handled = true;
    await ref.read(subscriptionStatusProvider.notifier).refresh();

    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (checkout == 'success') {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Suscripcion activada. ¡Disfruta TOGESC Pro!')),
      );
    } else if (checkout == 'cancel') {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Pago cancelado.')),
      );
    }

    final path = Uri.base.path;
    context.go(path.isEmpty || path == '/' ? '/' : path);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
