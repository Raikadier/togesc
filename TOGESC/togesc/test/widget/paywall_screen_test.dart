import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/screens/paywall_screen.dart';
import 'package:togesc/widgets/paywall_views.dart';

Future<void> _pump(WidgetTester tester, Size size, {String? feature}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionStatusProvider.overrideWith(
          () => _FreeSubscriptionNotifier(),
        ),
      ],
      child: MaterialApp(home: PaywallScreen(feature: feature)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PaywallScreen muestra features Pro', (tester) async {
    await _pump(tester, const Size(400, 2000));

    expect(find.text('Pasa a TOGESC Pro'), findsOneWidget);
    // Beneficio del pitch y fila de la tabla comparativa.
    expect(find.text('Acordes, aleatorio y modo velocidad'), findsOneWidget);
    expect(find.text('Acordes y aleatorio'), findsOneWidget);
    expect(find.text('Gratis o Pro'), findsOneWidget);
  });

  testWidgets('la tabla «Gratis o Pro» lista todas las filas con icono y '
      'etiqueta accesible', (tester) async {
    await _pump(tester, const Size(400, 2000));

    final table = find.byKey(const ValueKey('paywall-compare'));
    expect(table, findsOneWidget);
    for (final row in paywallCompareRows) {
      expect(
        find.descendant(of: table, matching: find.text(row.label)),
        findsOneWidget,
        reason: row.label,
      );
    }
    // Color nunca es la única señal: 4 filas solo Pro → 4 guiones.
    final onlyPro = paywallCompareRows.where((r) => !r.free).length;
    expect(
      find.descendant(of: table, matching: find.byIcon(Icons.remove_rounded)),
      findsNWidgets(onlyPro),
    );
    expect(
      find.bySemanticsLabel('Modo velocidad: Gratis, no; Pro, sí'),
      findsOneWidget,
    );
  });

  testWidgets('sin precios inventados: no aparece ninguna cifra en euros', (
    tester,
  ) async {
    await _pump(tester, const Size(400, 2000));
    expect(find.textContaining('€'), findsNothing);
  });

  testWidgets('desde un candado muestra la píldora «Desbloquea …»', (
    tester,
  ) async {
    await _pump(tester, const Size(400, 2000), feature: 'historial');
    expect(find.byKey(const ValueKey('paywall-unlock')), findsOneWidget);
    expect(find.textContaining('Desbloquea'), findsOneWidget);
  });

  testWidgets('en escritorio el pitch y el panel van lado a lado', (
    tester,
  ) async {
    await _pump(tester, const Size(1280, 900));

    final pitch = tester.getTopLeft(find.byType(PaywallPitch));
    final panel = tester.getTopLeft(
      find.byKey(const ValueKey('paywall-panel')),
    );
    expect(panel.dx, greaterThan(pitch.dx));
    expect(tester.takeException(), isNull);
  });
}

class _FreeSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async => const SubscriptionStatus.free();
}
