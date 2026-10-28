import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/providers/router_provider.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/screens/onboarding_screen.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('primera apertura redirige a onboarding', (tester) async {
    final router = buildAppRouter(onboardingComplete: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [goRouterProvider.overrideWithValue(router)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // v2.1: onboarding en 4 pasos; abre en la bienvenida.
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Paso 1 de 4'), findsOneWidget);
    expect(find.text('Entrenador de oído absoluto'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Cómo funciona'), findsOneWidget);
  });

  testWidgets('usuario existente abre home sin onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({onboardingCompleteKey: true});
    final router = buildAppRouter(onboardingComplete: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [goRouterProvider.overrideWithValue(router)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Independiente del copy de Home (rediseño v2, lote 1A).
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Entendido, empezar'), findsNothing);
  });

  testWidgets('replay desde about vuelve a onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({onboardingCompleteKey: true});
    final router = GoRouter(
      initialLocation: AppRoutes.about,
      refreshListenable: routerRefreshListenable,
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final done = prefs.getBool(onboardingCompleteKey) ?? false;
        final location = state.matchedLocation;
        if (!done && location != AppRoutes.onboarding) {
          return AppRoutes.onboarding;
        }
        if (done && location == AppRoutes.onboarding) {
          return AppRoutes.home;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const Scaffold(body: Text('OnboardingScreen')),
        ),
        GoRoute(
          path: AppRoutes.about,
          builder: (_, _) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final prefs = AppPreferences(
                  await SharedPreferences.getInstance(),
                );
                await prefs.setOnboardingComplete(false);
                routerRefreshListenable.value++;
              },
              child: const Text('Replay'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('HomeScreen')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Replay'), findsOneWidget);
    await tester.tap(find.text('Replay'));
    await tester.pumpAndSettle();

    expect(find.text('OnboardingScreen'), findsOneWidget);
  });
}
