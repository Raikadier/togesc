import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/screens/account_screen.dart';
import 'package:togesc/screens/game_screen.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/screens/speed_mode_select_screen.dart';
import 'package:togesc/screens/statistics_screen.dart';
import 'package:togesc/screens/subscription_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/widgets/togesc_shell.dart';

class _TestSRSNotifier extends AsyncNotifier<SRSSystem> implements SRSNotifier {
  final SRSSystem _srs;
  _TestSRSNotifier(this._srs);

  @override
  Future<SRSSystem> build() async => _srs;

  @override
  Future<void> saveProgress() async => _srs.saveProgress();

  @override
  Future<void> resetProgress() async {
    await _srs.resetProgress();
    ref.invalidateSelf();
  }
}

class _TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async {
    return const SubscriptionStatus(plan: 'pro', status: 'active');
  }
}

Finder _nav(TogescNavDestination d) => find.byKey(ValueKey('nav-${d.name}'));

void main() {
  group('E2E v2: smoke de la aplicación completa', () {
    late ProviderContainer container;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({onboardingCompleteKey: true});
      final srs = SRSSystem(
        repository: InMemoryProgressRepository(),
        random: Random(42),
        clock: () => DateTime(2026, 1, 1),
      );
      await srs.loadProgress();

      container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(
            InMemoryProgressRepository(),
          ),
          srsSystemProvider.overrideWith(() => _TestSRSNotifier(srs)),
          subscriptionStatusProvider.overrideWith(
            () => _TestSubscriptionNotifier(),
          ),
          audioPlayerServiceProvider.overrideWithValue(
            AudioPlayerService(generator: AudioGenerator(random: Random(42))),
          ),
          audioGeneratorProvider.overrideWithValue(
            AudioGenerator(random: Random(42)),
          ),
        ],
      );
      await container.read(srsSystemProvider.future);
      await container.read(subscriptionStatusProvider.future);
    });

    tearDown(() => container.dispose());

    /// App con el router real (shell con las 4 pestañas), en móvil.
    Future<void> pumpApp(
      WidgetTester tester, {
      Size size = const Size(400, 900),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      WidgetController.hitTestWarningShouldBeFatal = true;
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

      final router = createAppRouter(refreshListenable: ValueNotifier(0));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la app arranca en el Home v2 sin errores', (tester) async {
      await pumpApp(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('TOGESC'), findsWidgets);
      expect(find.byKey(const ValueKey('today-session-hero')), findsOneWidget);
      expect(find.byKey(const ValueKey('today-start-cta')), findsOneWidget);
      expect(find.text('Empezar sesión'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-week-strip')), findsOneWidget);
      expect(find.byType(TogescBottomNav), findsOneWidget);
      for (final d in TogescNavDestination.values) {
        expect(_nav(d), findsOneWidget, reason: d.label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('recorre las 4 pestañas: Práctica, Progreso, Velocidad y '
        'Perfil', (tester) async {
      await pumpApp(tester);

      await tester.tap(_nav(TogescNavDestination.progress));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
      expect(find.text('Progreso'), findsWidgets);

      await tester.tap(_nav(TogescNavDestination.speed));
      await tester.pumpAndSettle();
      expect(find.byType(SpeedModeSelectScreen), findsOneWidget);
      expect(find.text('Velocidad — Elige modo'), findsOneWidget);

      await tester.tap(_nav(TogescNavDestination.profile));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);

      await tester.tap(_nav(TogescNavDestination.practice));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pro se abre desde Perfil («TOGESC Pro»)', (tester) async {
      await pumpApp(tester);

      await tester.tap(_nav(TogescNavDestination.profile));
      await tester.pumpAndSettle();

      final entry = find.byKey(const ValueKey('account-pro-entry'));
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: entry, matching: find.text('TOGESC Pro')),
        findsOneWidget,
      );
      await tester.tap(entry);
      await tester.pumpAndSettle();

      // Usuario Pro → gestión de la suscripción, sin salir de Perfil.
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('práctica libre: cada tile abre su sesión', (tester) async {
      await pumpApp(tester);

      for (final mode in ['singleNote', 'interval', 'chord']) {
        final tile = find.byKey(ValueKey('free-tile-$mode'));
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        // La sesión anima en bucle: sin pumpAndSettle.
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(GameScreen), findsOneWidget, reason: mode);
        // v2.1: «Preparado» siempre al entrar; sin empezar, volver sale.
        expect(find.text('PREPARADO'), findsOneWidget, reason: mode);
        expect(
          find.byKey(const ValueKey('session-start')),
          findsOneWidget,
          reason: mode,
        );

        await tester.tap(find.byTooltip('Volver'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget, reason: mode);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
