// PT-10 (pentest dinámico, caso 3): content spoofing en /paywall?feature=…
//
// Antes, el parámetro `feature` de la URL se interpolaba sin validar en el
// título del paywall (`'Desbloquea $feature'`). Flutter Web pinta con
// CanvasKit (no había XSS), pero se podía inyectar texto arbitrario —incluido
// unicode y RTL— en una pantalla de pago de confianza.
//
// Arreglo: `SubscriptionConstants.paywallFeatureTitle` solo acepta las
// funciones Pro que genera la app (allowlist); el resto usa el título genérico.
// Estos tests verifican el arreglo (originalmente documentaban el FAIL).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/subscription_constants.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/screens/paywall_screen.dart';

Future<String> _pumpPaywall(WidgetTester tester, String? feature) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        subscriptionStatusProvider.overrideWith(() => _FreeSubscriptionNotifier()),
      ],
      child: MaterialApp(home: PaywallScreen(feature: feature)),
    ),
  );
  await tester.pumpAndSettle();

  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
      .join('\n');
}

void main() {
  testWidgets('texto atacante arbitrario NO se refleja: usa el título genérico',
      (tester) async {
    const payload = 'GRATIS. Llama al +34 600 000 000 para activar';
    final text = await _pumpPaywall(tester, payload);

    expect(text, isNot(contains(payload)));
    expect(text, isNot(contains('Desbloquea $payload')));
    expect(text, contains('Pasa a TOGESC Pro'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unicode/RTL y cadena larga no se reflejan ni provocan crash',
      (tester) async {
    final payload = '\u202Eevil\u202C ${'A' * 300} 😈🔓';
    final text = await _pumpPaywall(tester, payload);

    expect(text, isNot(contains('evil')));
    expect(text, contains('Pasa a TOGESC Pro'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadena tipo HTML/script no se refleja', (tester) async {
    const payload = '<script>alert(1)</script>';
    final text = await _pumpPaywall(tester, payload);

    expect(text, isNot(contains('<script>')));
    expect(text, contains('Pasa a TOGESC Pro'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin feature usa el título por defecto (comportamiento seguro)',
      (tester) async {
    final text = await _pumpPaywall(tester, null);
    expect(text, contains('Pasa a TOGESC Pro'));
  });

  testWidgets('las funciones Pro conocidas sí se muestran (allowlist)',
      (tester) async {
    for (final mode in SubscriptionConstants.proGameModes) {
      final label = SubscriptionConstants.modeProLabel(mode);
      final text = await _pumpPaywall(tester, label);
      expect(text, contains('Desbloquea $label'));
    }
    final text =
        await _pumpPaywall(tester, SubscriptionConstants.historyFeatureKey);
    expect(text, contains('Desbloquea historial'));
  });
}

class _FreeSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async => const SubscriptionStatus.free();
}
