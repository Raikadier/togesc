import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/screens/paywall_screen.dart';

void main() {
  testWidgets('PaywallScreen muestra features Pro', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionStatusProvider.overrideWith(
            () => _FreeSubscriptionNotifier(),
          ),
        ],
        child: const MaterialApp(home: PaywallScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pasa a TOGESC Pro'), findsOneWidget);
    expect(find.textContaining('Acordes'), findsOneWidget);
  });
}

class _FreeSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async => const SubscriptionStatus.free();
}
