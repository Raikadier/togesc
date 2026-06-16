import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../constants/game_constants.dart';
import '../constants/subscription_constants.dart';
import '../providers/subscription_provider.dart';
import '../services/subscription_access.dart';

/// Bloquea rutas Pro y redirige al paywall si hace falta.
class ProRouteGuard extends ConsumerWidget {
  const ProRouteGuard({
    required this.mode,
    required this.child,
    super.key,
  });

  final GameMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return statusAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => child,
      data: (status) {
        if (SubscriptionConstants.isModeFree(mode) ||
            SubscriptionAccess.hasProAccess(status)) {
          return child;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.replace(
            '${AppRoutes.paywall}?feature=${Uri.encodeComponent(SubscriptionConstants.modeProLabel(mode))}',
          );
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
