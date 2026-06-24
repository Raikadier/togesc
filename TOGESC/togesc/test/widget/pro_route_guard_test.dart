import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/config/subscription_config.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/widgets/pro_route_guard.dart';

class _FailingSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async {
    throw StateError('network');
  }
}

class _ProSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async {
    lastKnown = const SubscriptionStatus(
      plan: 'pro',
      status: 'active',
    );
    return lastKnown!;
  }
}

void main() {
  Widget buildGuard({
    required SubscriptionNotifier notifier,
    required GameMode mode,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ProRouteGuard(
            mode: mode,
            child: const Scaffold(body: Text('pro-content')),
          ),
        ),
        GoRoute(
          path: AppRoutes.paywall,
          builder: (_, __) => const Scaffold(body: Text('paywall')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        subscriptionStatusProvider.overrideWith(() => notifier),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('error sin cache redirige a paywall en modo Pro', (tester) async {
    await tester.pumpWidget(
      buildGuard(
        notifier: _FailingSubscriptionNotifier(),
        mode: GameMode.chord,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('pro-content'), findsNothing);
    expect(find.text('paywall'), findsOneWidget);
  }, skip: !SubscriptionConfig.isActive);

  testWidgets('error con cache Pro permite acceso', (tester) async {
    await tester.pumpWidget(
      buildGuard(
        notifier: _ProSubscriptionNotifier(),
        mode: GameMode.chord,
      ),
    );
    await tester.pump();

    expect(find.text('pro-content'), findsOneWidget);
  });
}
