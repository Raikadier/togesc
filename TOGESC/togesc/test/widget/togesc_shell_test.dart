import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/screens/account_screen.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/screens/paywall_screen.dart';
import 'package:togesc/screens/speed_mode_select_screen.dart';
import 'package:togesc/screens/statistics_screen.dart';
import 'package:togesc/screens/subscription_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/widgets/togesc_shell.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({onboardingCompleteKey: true});
  });

  Finder navItem(TogescNavDestination d) =>
      find.byKey(ValueKey('nav-${d.name}'));
  Finder railItem(TogescNavDestination d) =>
      find.byKey(ValueKey('rail-${d.name}'));

  Future<GoRouter> pumpShell(
    WidgetTester tester, {
    Size size = const Size(400, 900),
    String initialLocation = AppRoutes.home,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(
      refreshListenable: ValueNotifier(0),
      initialLocation: initialLocation,
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// Icono relleno + `primary` + negrita en el activo; contorno en el resto.
  void expectActive(WidgetTester tester, TogescNavDestination active) {
    for (final d in TogescNavDestination.values) {
      final item = navItem(d);
      final isActive = d == active;
      final icon = tester.widget<Icon>(
        find.descendant(of: item, matching: find.byType(Icon)),
      );
      expect(icon.icon, isActive ? d.selectedIcon : d.icon, reason: d.label);
      final text = tester.widget<Text>(
        find.descendant(of: item, matching: find.text(d.label)),
      );
      expect(
        text.style?.fontWeight,
        isActive ? FontWeight.w700 : isNot(FontWeight.w700),
      );
      if (isActive) expect(icon.color, DesignTokens.primary);
    }
  }

  group('barra inferior móvil', () {
    testWidgets('muestra los 4 destinos v2 y no la pestaña Pro', (
      tester,
    ) async {
      await pumpShell(tester);

      expect(find.text('TOGESC'), findsOneWidget);
      expect(find.byType(TogescBottomNav), findsOneWidget);
      expect(find.byType(TogescNavRail), findsNothing);
      for (final label in ['Práctica', 'Progreso', 'Velocidad', 'Perfil']) {
        expect(
          find.descendant(
            of: find.byType(TogescBottomNav),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      expect(find.text('Pro'), findsNothing);
      expect(find.text('Estadísticas'), findsNothing);
      expect(
        tester.getSize(find.byType(TogescBottomNav)).height,
        greaterThanOrEqualTo(DesignTokens.navBarHeight),
      );
      expectActive(tester, TogescNavDestination.practice);
    });

    testWidgets('shell muestra bottom nav y navega a estadisticas', (
      tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(navItem(TogescNavDestination.progress));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsScreen), findsOneWidget);
      expectActive(tester, TogescNavDestination.progress);
    });

    testWidgets('tab Velocidad abre la selección de velocidad', (tester) async {
      await pumpShell(tester);

      await tester.tap(navItem(TogescNavDestination.speed));
      await tester.pumpAndSettle();

      expect(find.byType(SpeedModeSelectScreen), findsOneWidget);
      expect(find.byType(TogescBottomNav), findsOneWidget);
      expectActive(tester, TogescNavDestination.speed);
    });

    testWidgets('shell tab perfil abre cuenta', (tester) async {
      await pumpShell(tester);

      await tester.tap(navItem(TogescNavDestination.profile));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
      expectActive(tester, TogescNavDestination.profile);
    });

    testWidgets('tab practica vuelve a home', (tester) async {
      await pumpShell(tester);

      await tester.tap(navItem(TogescNavDestination.progress));
      await tester.pumpAndSettle();
      await tester.tap(navItem(TogescNavDestination.practice));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expectActive(tester, TogescNavDestination.practice);
    });

    testWidgets('destinos con etiqueta semántica, seleccionado y ≥48', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpShell(tester);

      for (final d in TogescNavDestination.values) {
        expect(
          tester.getSemantics(navItem(d)),
          isSemantics(
            label: d.label,
            isButton: true,
            hasSelectedState: true,
            isSelected: d == TogescNavDestination.practice,
            hasTapAction: true,
          ),
        );
        final size = tester.getSize(navItem(d));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
      handle.dispose();
    });

    testWidgets('a 800 px sigue la barra inferior (rail solo ≥1024)', (
      tester,
    ) async {
      await pumpShell(tester, size: const Size(800, 900));

      expect(find.byType(TogescBottomNav), findsOneWidget);
      expect(find.byType(TogescNavRail), findsNothing);
    });
  });

  group('Pro fuera de la nav (D8)', () {
    testWidgets('Perfil lleva a Pro con «TOGESC Pro»', (tester) async {
      await pumpShell(tester);

      await tester.tap(navItem(TogescNavDestination.profile));
      await tester.pumpAndSettle();

      final entry = find.byKey(const ValueKey('account-pro-entry'));
      expect(entry, findsOneWidget);
      expect(
        find.descendant(of: entry, matching: find.textContaining('TOGESC Pro')),
        findsOneWidget,
      );

      await tester.tap(entry);
      await tester.pumpAndSettle();

      // Build de test sin monetización: hasPro → pantalla de suscripción.
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expectActive(tester, TogescNavDestination.profile);
    });

    testWidgets('deep link /paywall sigue funcionando', (tester) async {
      await pumpShell(tester, initialLocation: AppRoutes.paywall);

      expect(find.byType(PaywallScreen), findsOneWidget);
      expectActive(tester, TogescNavDestination.profile);
    });

    testWidgets('deep link /paywall?feature=velocidad marca Velocidad', (
      tester,
    ) async {
      await pumpShell(
        tester,
        initialLocation:
            '${AppRoutes.paywall}?feature=${Uri.encodeComponent('Entrenamiento de velocidad')}',
      );

      expect(find.byType(PaywallScreen), findsOneWidget);
      expectActive(tester, TogescNavDestination.speed);
    });

    testWidgets('deep link /subscription sigue funcionando', (tester) async {
      await pumpShell(tester, initialLocation: AppRoutes.subscription);

      expect(find.byType(SubscriptionScreen), findsOneWidget);
    });
  });

  group('rail de escritorio', () {
    testWidgets('a ≥1024 muestra el rail de 76 con TG y 4 destinos', (
      tester,
    ) async {
      await pumpShell(tester, size: const Size(1200, 800));

      expect(find.byType(TogescNavRail), findsOneWidget);
      expect(find.byType(TogescBottomNav), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('TG'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TogescNavRail)).width,
        DesignTokens.railWidth,
      );
      for (final d in TogescNavDestination.values) {
        expect(tester.getSize(railItem(d)), const Size(48, 48));
      }
      expect(
        find.descendant(
          of: find.byType(TogescNavRail),
          matching: find.byTooltip('Pro'),
        ),
        findsNothing,
      );

      // Activo: fondo hero e icono acento.
      final activeMaterial = tester.widget<Material>(
        find
            .ancestor(
              of: railItem(TogescNavDestination.practice),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(activeMaterial.color, DesignTokens.hero);
      final activeIcon = tester.widget<Icon>(
        find.descendant(
          of: railItem(TogescNavDestination.practice),
          matching: find.byType(Icon),
        ),
      );
      expect(activeIcon.color, DesignTokens.onHeroAccent);
      expect(activeIcon.icon, TogescNavDestination.practice.selectedIcon);
    });

    testWidgets('el rail navega con clic', (tester) async {
      await pumpShell(tester, size: const Size(1200, 800));

      await tester.tap(railItem(TogescNavDestination.progress));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('el rail se usa con teclado (Tab + Enter)', (tester) async {
      await pumpShell(tester, size: const Size(1200, 800));

      final progressFocus = Focus.of(
        tester.element(
          find.descendant(
            of: railItem(TogescNavDestination.progress),
            matching: find.byType(Icon),
          ),
        ),
      );
      progressFocus.requestFocus();
      await tester.pump();
      expect(progressFocus.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('variante oscura de sesión', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                TogescNavRail(
                  dark: true,
                  selected: TogescNavDestination.practice,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final rail = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(TogescNavRail),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(rail.color, DesignTokens.sessionBackground);
    });
  });

  test('forLocation mapea rutas a destinos', () {
    TogescNavDestination at(String l) =>
        TogescNavDestination.forLocation(Uri.parse(l));
    expect(at('/'), TogescNavDestination.practice);
    expect(at('/statistics'), TogescNavDestination.progress);
    expect(at('/statistics/notes'), TogescNavDestination.progress);
    expect(at('/speed'), TogescNavDestination.speed);
    expect(at('/account'), TogescNavDestination.profile);
    expect(at('/subscription'), TogescNavDestination.profile);
    expect(at('/paywall'), TogescNavDestination.profile);
    expect(at('/paywall?feature=Acordes'), TogescNavDestination.profile);
  });
}
