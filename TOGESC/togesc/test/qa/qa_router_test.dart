import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/config/subscription_config.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/router_provider.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/screens/paywall_screen.dart';
import 'package:togesc/screens/speed_mode_select_screen.dart';
import 'package:togesc/services/app_preferences.dart';

import 'qa_support.dart';

class _FreeSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async => const SubscriptionStatus.free();
}

/// Router real de la app (`createAppRouter`) con onboarding completado.
Future<GoRouter> _pumpApp(WidgetTester tester, String location) async {
  SharedPreferences.setMockInitialValues({onboardingCompleteKey: true});
  final router = createAppRouter(
    refreshListenable: ValueNotifier<int>(0),
    initialLocation: location,
  );
  qaSetViewSize(tester, const Size(390, 844));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        goRouterProvider.overrideWithValue(router),
        subscriptionStatusProvider.overrideWith(
          () => _FreeSubscriptionNotifier(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Errores de framework que hubo durante el test (todos, no solo el primero).
List<Object> _drainExceptions(WidgetTester tester) {
  final errors = <Object>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    errors.add(e!);
  }
  return errors;
}

void main() {
  group('Router · rutas inválidas', () {
    testWidgets('ruta inexistente: pantalla en español con salida '
        '[BUG: router.dart:44 no define errorBuilder; GoRouter muestra su '
        'pantalla por defecto en inglés «Page Not Found» / «Home»]', (
      tester,
    ) async {
      await _pumpApp(tester, '/no-existe');
      expect(_drainExceptions(tester), isEmpty);
      expect(find.text('Page Not Found'), findsNothing);
      expect(find.text('Home'), findsNothing);
      // Algún texto en español y un botón que lleve al inicio.
      expect(
        find.textContaining(
          RegExp(
            'no existe|no encontrad|Volver|Ir al inicio',
            caseSensitive: false,
          ),
        ),
        findsWidgets,
      );
    }, skip: qaSkipBug);

    for (final location in const ['/game/999', '/game/abc', '/game/6']) {
      testWidgets('modeId inválido ($location): cae en el Home en español '
          'sin excepción', (tester) async {
        await _pumpApp(tester, location);
        expect(_drainExceptions(tester), isEmpty);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Page Not Found'), findsNothing);
      });
    }

    testWidgets('modeId de velocidad inválido: cae en el selector de '
        'velocidad sin excepción', (tester) async {
      await _pumpApp(tester, '/speed/game/999');
      expect(_drainExceptions(tester), isEmpty);
      expect(find.byType(SpeedModeSelectScreen), findsOneWidget);
    });
  });

  group('Paywall como ruta inicial (deep link, sin historial)', () {
    testWidgets('«Cerrar» no lanza y lleva al Home', (tester) async {
      await _pumpApp(tester, AppRoutes.paywall);
      expect(find.byType(PaywallScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      expect(_drainExceptions(tester), isEmpty);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets(
      '«Continuar» (monetización inactiva) no lanza y lleva al Home',
      (tester) async {
        await _pumpApp(tester, AppRoutes.paywall);
        final cta = find.widgetWithText(FilledButton, 'Continuar');
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(_drainExceptions(tester), isEmpty);
        expect(find.byType(HomeScreen), findsOneWidget);
      },
      skip: qaSkipBug || SubscriptionConfig.isActive,
    );

    testWidgets('con historial (push desde el Home) «Cerrar» vuelve atrás', (
      tester,
    ) async {
      final router = await _pumpApp(tester, AppRoutes.home);
      router.push(AppRoutes.paywall);
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(_drainExceptions(tester), isEmpty);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
