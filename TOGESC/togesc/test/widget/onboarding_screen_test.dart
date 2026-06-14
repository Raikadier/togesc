import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/screens/onboarding_screen.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('muestra las tres secciones pedagogicas', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Repeticion espaciada (SRS)'), findsOneWidget);
    expect(find.text('Variacion de octavas y timbres'), findsOneWidget);
    expect(find.text('Limpieza tonal'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Entendido, empezar'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Entendido, empezar'), findsOneWidget);
  });

  testWidgets('completar onboarding guarda preferencia', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: AppRoutes.onboarding,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byType(FilledButton);
    await tester.scrollUntilVisible(
      button,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    final prefs = AppPreferences(await SharedPreferences.getInstance());
    expect(prefs.onboardingComplete, isTrue);
    expect(find.text('Home'), findsOneWidget);
  });
}
