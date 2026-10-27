import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/app/app_theme.dart';
import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/providers/clock_provider.dart';
import 'package:togesc/screens/account_screen.dart';
import 'package:togesc/screens/statistics_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/widgets/togesc_shell.dart';

/// Tema oscuro de las pantallas v2 del shell (Home, Progreso, Perfil, barra
/// inferior y rail). Base: paleta de sesión (#141018, #1A121E, #241B2A,
/// #3A2E42, #ECE0E8, #9C8FA3 y acento #DA9CFF).
void main() {
  const page = Color(0xFF141018);
  const surface = Color(0xFF1A121E);
  const muted = Color(0xFF241B2A);
  const border = Color(0xFF3A2E42);
  const accent = Color(0xFFDA9CFF);

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({onboardingCompleteKey: true});
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    required Size size,
    String location = AppRoutes.home,
    ThemeMode mode = ThemeMode.dark,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = createAppRouter(
      refreshListenable: ValueNotifier(0),
      initialLocation: location,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Miércoles: hay días pasados, hoy y futuros en la semana L–D.
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 18)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color firstMaterialColor(WidgetTester tester, Finder of) {
    final material = tester.widget<Material>(
      find.descendant(of: of, matching: find.byType(Material)).first,
    );
    return material.color!;
  }

  Color textColor(WidgetTester tester, Finder text) =>
      tester.widget<Text>(text).style!.color!;

  Material tileMaterial(WidgetTester tester, String mode) =>
      tester.widget<Material>(
        find
            .ancestor(
              of: find.byKey(ValueKey('free-tile-$mode')),
              matching: find.byType(Material),
            )
            .first,
      );

  BoxDecoration weekCell(WidgetTester tester, int weekday) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(ValueKey('week-day-$weekday')),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  group('tema oscuro · móvil (400×900)', () {
    testWidgets('barra inferior, cabecera y logo siguen el tema oscuro', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(400, 900));

      expect(find.byType(TogescBottomNav), findsOneWidget);
      expect(firstMaterialColor(tester, find.byType(TogescBottomNav)), surface);

      final logo = textColor(tester, find.text('TOGESC').first);
      expect(logo, accent);
      expect(contrastRatio(logo, page), greaterThanOrEqualTo(4.5));

      // Destino activo e inactivo de la barra: AA sobre #1A121E.
      for (final d in TogescNavDestination.values) {
        final label = textColor(
          tester,
          find.descendant(
            of: find.byKey(ValueKey('nav-${d.name}')),
            matching: find.text(d.label),
          ),
        );
        expect(
          contrastRatio(label, surface),
          greaterThanOrEqualTo(4.5),
          reason: d.label,
        );
      }
    });

    testWidgets('Home: tiles de práctica libre, «Ver todos» y semana', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(400, 1600));

      final tile = tileMaterial(tester, 'singleNote');
      expect(tile.color, surface);
      expect((tile.shape! as RoundedRectangleBorder).side.color, border);
      final tileTitle = find.descendant(
        of: find.byKey(const ValueKey('free-tile-singleNote')),
        matching: find.byType(Text),
      );
      for (final t in tester.widgetList<Text>(tileTitle)) {
        expect(
          contrastRatio(t.style!.color!, surface),
          greaterThanOrEqualTo(4.5),
          reason: t.data,
        );
      }

      final seeAll = tester.widget<TextButton>(
        find.byKey(const ValueKey('home-see-all-modes')),
      );
      final seeAllColor = seeAll.style!.foregroundColor!.resolve({})!;
      expect(seeAllColor, accent);
      expect(contrastRatio(seeAllColor, page), greaterThanOrEqualTo(4.5));

      // Sin práctica: los 6 días anteriores son «sin práctica» sobre
      // #241B2A; hoy (miércoles, pendiente) va sobre la superficie de tile
      // con borde discontinuo de acento (v2.1).
      for (var weekday = 1; weekday <= 7; weekday++) {
        final cell = weekCell(tester, weekday);
        final today = weekday == 3;
        final bg = today ? surface : muted;
        expect(cell.color, bg, reason: 'día $weekday');
        final label = tester.widget<Text>(
          find
              .descendant(
                of: find.byKey(ValueKey('week-day-$weekday')),
                matching: find.byType(Text),
              )
              .first,
        );
        expect(
          contrastRatio(label.style!.color!, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'día $weekday',
        );
      }
      // Hoy (miércoles) pendiente: borde discontinuo de acento.
      final dashed = find.byKey(const ValueKey('week-today-pending'));
      expect(dashed, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('week-day-3')),
          matching: dashed,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Progreso: celdas sin datos y paneles oscuros con AA', (
      tester,
    ) async {
      await pumpApp(
        tester,
        size: const Size(400, 2400),
        location: AppRoutes.statistics,
      );
      expect(find.byType(StatisticsScreen), findsOneWidget);

      final cell = tester.widget<Material>(
        find.byKey(const ValueKey('mastery-cell-C')),
      );
      expect(cell.color, muted);
      for (final t in tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('mastery-cell-C')),
          matching: find.byType(Text),
        ),
      )) {
        expect(
          contrastRatio(t.style!.color!, muted),
          greaterThanOrEqualTo(4.5),
        );
      }
      // Ningún panel del Progreso conserva el blanco del tema claro.
      final lightPanels = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final d = c.decoration;
            return d is BoxDecoration &&
                (d.color == DesignTokens.surfaceContainerLowest ||
                    d.color == DesignTokens.masteryEmpty);
          });
      expect(lightPanels, isEmpty);
    });

    testWidgets('Perfil: se pinta sobre el fondo oscuro', (tester) async {
      await pumpApp(
        tester,
        size: const Size(400, 1600),
        location: AppRoutes.account,
      );
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(AccountScreen));
      expect(Theme.of(context).scaffoldBackgroundColor, page);
      expect(firstMaterialColor(tester, find.byType(TogescBottomNav)), surface);
    });
  });

  group('tema oscuro · escritorio (1280×800, rail)', () {
    testWidgets('el rail es oscuro y su logo y destinos tienen AA', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(1280, 800));

      expect(find.byType(TogescNavRail), findsOneWidget);
      expect(find.byType(TogescBottomNav), findsNothing);
      final rail = find.byType(TogescNavRail);
      expect(firstMaterialColor(tester, rail), surface);

      final railBox = tester.widget<Container>(
        find.descendant(of: rail, matching: find.byType(Container)).first,
      );
      expect(
        ((railBox.decoration! as BoxDecoration).border! as Border).right.color,
        border,
      );

      final tg = textColor(
        tester,
        find.descendant(of: rail, matching: find.text('TG')),
      );
      expect(tg, accent);
      expect(contrastRatio(tg, surface), greaterThanOrEqualTo(4.5));

      final inactive = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const ValueKey('rail-progress')),
          matching: find.byType(Icon),
        ),
      );
      expect(
        contrastRatio(inactive.color!, surface),
        greaterThanOrEqualTo(4.5),
      );

      // El Home de escritorio también pierde las tiles claras.
      expect(tileMaterial(tester, 'singleNote').color, surface);
    });
  });

  group('tema claro (regresión)', () {
    testWidgets('rail, tiles y semana conservan los tokens claros', (
      tester,
    ) async {
      await pumpApp(
        tester,
        size: const Size(1280, 1400),
        mode: ThemeMode.light,
      );

      expect(
        firstMaterialColor(tester, find.byType(TogescNavRail)),
        DesignTokens.navBar,
      );
      expect(
        tileMaterial(tester, 'singleNote').color,
        DesignTokens.surfaceContainerLowest,
      );
      expect(weekCell(tester, 1).color, DesignTokens.masteryEmpty);
      final seeAll = tester.widget<TextButton>(
        find.byKey(const ValueKey('home-see-all-modes')),
      );
      expect(seeAll.style!.foregroundColor!.resolve({}), DesignTokens.primary);
    });
  });
}
