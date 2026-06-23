import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/screens/account_screen.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/screens/statistics_screen.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({onboardingCompleteKey: true});
  });

  GoRouter buildRouter() {
    final refresh = ValueNotifier(0);
    return createAppRouter(refreshListenable: refresh);
  }

  Future<void> pumpMobileShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shell muestra bottom nav y navega a estadisticas', (tester) async {
    await pumpMobileShell(tester);

    expect(find.text('TOGESC'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsScreen), findsOneWidget);
  });

  testWidgets('shell tab perfil abre cuenta', (tester) async {
    await pumpMobileShell(tester);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
  });

  testWidgets('tab practica vuelve a home', (tester) async {
    await pumpMobileShell(tester);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practica'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
