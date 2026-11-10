import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/screens/privacy_policy_screen.dart';

/// PT-03: la política debe describir lo que la app hace de verdad.
void main() {
  Future<String> renderedPolicyText(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 20000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
    await tester.pumpAndSettle();

    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join('\n');
  }

  testWidgets('declara analítica activa por defecto con user_id y cómo evitarla',
      (tester) async {
    final text = await renderedPolicyText(tester);

    expect(text, contains('activa por defecto'));
    expect(text, contains('user_id'));
    expect(text, contains('ANALYTICS_ENABLED=false'));
    expect(text, isNot(contains('No hay analítica')));
    expect(text, isNot(contains('No usamos servicios de analítica')));
  });

  testWidgets('declara CSAT, Sentry, Google, pagos y encargados', (tester) async {
    final text = await renderedPolicyText(tester);

    expect(text, contains('texto libre'));
    expect(text, contains('Sentry'));
    expect(text, contains('fonts.gstatic.com'));
    expect(text, contains('CanvasKit'));
    expect(text, contains('Stripe'));
    expect(text, contains('RevenueCat'));
    expect(text, contains('encargado del tratamiento'));
    expect(text, contains('Vercel'));
    expect(text, contains('cuenta opcional (Supabase)'));
  });
}
