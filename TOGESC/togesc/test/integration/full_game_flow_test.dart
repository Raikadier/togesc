import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/models/subscription_status.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/game_session_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/providers/subscription_provider.dart';
import 'package:togesc/screens/game_screen.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/screens/statistics_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/widgets/piano_keyboard.dart';
import 'package:togesc/widgets/progress_v2/recent_sessions_list.dart';

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

/// Usuario gratis: la «Sesión de hoy» (una nota) es un modo libre.
class _FreeSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<SubscriptionStatus> build() async => const SubscriptionStatus.free();
}

/// Sesión corta: 5 rondas (la meta más pequeña de Ajustes), sin cluster.
const _targetRounds = 5;

void main() {
  group('Integración v2: Home → sesión → Progreso', () {
    late ProviderContainer container;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        onboardingCompleteKey: true,
        sessionRoundGoalV2Key: _targetRounds,
        clusterEnabledKey: false,
      });
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
            () => _FreeSubscriptionNotifier(),
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
      // Como en la app real, la suscripción ya está resuelta cuando el
      // usuario toca el CTA (si no, ProRouteGuard pinta un frame de carga).
      await container.read(subscriptionStatusProvider.future);
    });

    tearDown(() => container.dispose());

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
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

    /// La sesión tiene animaciones en bucle (barras de escucha): se avanza
    /// el reloj por pasos en lugar de `pumpAndSettle`.
    Future<void> pumpFor(WidgetTester tester, Duration total) async {
      const step = Duration(milliseconds: 100);
      var elapsed = Duration.zero;
      while (elapsed < total) {
        await tester.pump(step);
        elapsed += step;
      }
    }

    /// Espera a la fase `answer` (listen dura ≥1,5 s) y devuelve la nota.
    Future<String> waitForAnswer(WidgetTester tester, int round) async {
      expect(
        find.text('ESCUCHANDO'),
        findsOneWidget,
        reason: 'ronda $round empieza en listen',
      );
      await pumpFor(tester, const Duration(milliseconds: 1800));
      expect(
        find.text('RESPONDE'),
        findsOneWidget,
        reason: 'ronda $round pasa a answer',
      );
      expect(find.text('$round / $_targetRounds'), findsOneWidget);
      final notes = container.read(gameSessionProvider).currentNotes;
      expect(notes, hasLength(1));
      return notes.single;
    }

    /// Bombea hasta que [finder] aparezca (espera por condición).
    Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
      for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(finder, findsWidgets);
    }

    Future<void> tapKey(WidgetTester tester, String note) async {
      // Las blancas quedan tapadas por las negras en su mitad superior: se
      // toca la franja inferior, como un dedo real.
      final key = find.byKey(ValueKey('piano-key-$note'));
      final rect = tester.getRect(key);
      await tester.tapAt(
        note.endsWith('#')
            ? rect.center
            : rect.bottomCenter - const Offset(0, 16),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    PianoKeyboard piano(WidgetTester tester) =>
        tester.widget<PianoKeyboard>(find.byType(PianoKeyboard));

    testWidgets('el CTA «Empezar sesión» entra directo en listen', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      final cta = find.byKey(const ValueKey('today-start-cta'));
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      await tester.tap(cta);
      await pumpUntilFound(tester, find.byType(GameScreen));

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Toca para empezar'), findsNothing);
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      await waitForAnswer(tester, 1);

      // Salir sin rondas: no se registra historial ni queda la sesión viva.
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets(
      'sesión completa: acierto y fallo sobre la tecla, avance automático '
      'y resultado en Progreso',
      (tester) async {
        await pumpApp(tester);

        final cta = find.byKey(const ValueKey('today-start-cta'));
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await pumpUntilFound(tester, find.text('ESCUCHANDO'));

        // Ronda 1: acierto → la tecla tocada queda en verde.
        final first = await waitForAnswer(tester, 1);
        await tapKey(tester, first);
        expect(find.text('CORRECTO'), findsOneWidget);
        expect(piano(tester).correctNotes, {first});
        expect(piano(tester).incorrectNotes, isEmpty);
        expect(find.text('Siguiente ronda en un momento…'), findsOneWidget);

        // Avance automático a los 2,2 s, sin pulsar nada.
        await pumpFor(tester, const Duration(milliseconds: 2400));
        expect(find.text('CORRECTO'), findsNothing);

        // Ronda 2: fallo → correcta en verde y errónea en rojo.
        final second = await waitForAnswer(tester, 2);
        final wrong = second == 'C' ? 'D' : 'C';
        await tapKey(tester, wrong);
        expect(find.text('INCORRECTO'), findsOneWidget);
        expect(find.text('Era $second, respondiste $wrong'), findsOneWidget);
        expect(piano(tester).correctNotes, {second});
        expect(piano(tester).incorrectNotes, {wrong});
        await pumpFor(tester, const Duration(milliseconds: 2400));

        // Rondas 3..5: aciertos.
        for (var round = 3; round <= _targetRounds; round++) {
          final note = await waitForAnswer(tester, round);
          await tapKey(tester, note);
          expect(find.text('CORRECTO'), findsOneWidget);
          if (round < _targetRounds) {
            await pumpFor(tester, const Duration(milliseconds: 2400));
          }
        }

        // Meta cumplida: no avanza solo y ofrece volver.
        final session = container.read(gameSessionProvider);
        expect(session.goalReached, isTrue);
        expect(session.roundsCompleted, _targetRounds);
        expect(session.correctRounds, _targetRounds - 1);
        await pumpFor(tester, const Duration(milliseconds: 2400));
        expect(find.textContaining('Objetivo cumplido'), findsOneWidget);
        final back = find.text('Volver al inicio');
        expect(back, findsOneWidget);
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);

        // Progreso refleja la sesión recién terminada.
        await tester.tap(find.byKey(const ValueKey('nav-progress')));
        await tester.pumpAndSettle();
        expect(find.byType(StatisticsScreen), findsOneWidget);
        expect(find.byKey(const Key('progress-empty-state')), findsNothing);
        final row = find.text(
          '$_targetRounds rondas · ${_targetRounds - 1} aciertos',
        );
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(row, findsOneWidget);
        final sessionRow = find.ancestor(
          of: row,
          matching: find.byType(SessionLogRow),
        );
        expect(
          find.descendant(of: sessionRow, matching: find.text('80%')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
