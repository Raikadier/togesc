import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/app_theme.dart';
import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/app/togesc_colors.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/speed_best_streak_provider.dart';
import 'package:togesc/providers/speed_session_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/screens/speed_game_screen.dart';
import 'package:togesc/screens/speed_mode_select_screen.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/widgets/countdown_timer_widget.dart';
import 'package:togesc/widgets/speed_mode_select_views.dart';
import 'package:togesc/widgets/speed_session_views.dart';

class _FakeSRSNotifier extends AsyncNotifier<SRSSystem> implements SRSNotifier {
  final SRSSystem _srs;
  _FakeSRSNotifier(this._srs);

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

/// Audio sin hardware: mismo contrato que [AudioPlayerService].
class _SilentAudio extends AudioPlayerService {
  _SilentAudio() : super(generator: AudioGenerator(random: Random(7)));

  int plays = 0;

  @override
  bool get isInitialized => true;

  @override
  void captureUserGesture() {}

  @override
  Future<bool> waitUntilReady() async => true;

  @override
  Future<void> playBuffer(Float64List samples, {int? sampleRate}) async {
    plays++;
  }
}

/// Lote 3: velocidad adopta los tokens v2 y la sesión oscura.
void main() {
  late SRSSystem srs;
  late InMemoryProgressRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = InMemoryProgressRepository();
    srs = SRSSystem(
      repository: repo,
      random: Random(42),
      clock: () => DateTime(2026, 1, 1),
    );
    await srs.loadProgress();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        audioPlayerServiceProvider.overrideWithValue(_SilentAudio()),
        audioGeneratorProvider.overrideWithValue(
          AudioGenerator(random: Random(42)),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );
  }

  group('Contraste de los tokens de velocidad', () {
    test('acento claro AA como relleno y como texto', () {
      const light = TogescColors.light;
      expect(
        contrastRatio(light.onSpeedAccent, light.speedAccent),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(light.speedAccent, DesignTokens.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(light.speedAccent, DesignTokens.speedContainer),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('acento oscuro y de sesión AA', () {
      for (final c in [TogescColors.dark, TogescColors.session]) {
        expect(c.speedAccent, DesignTokens.speedAccentOnDark);
        expect(
          contrastRatio(c.onSpeedAccent, c.speedAccent),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(c.speedAccent, DesignTokens.sessionBackground),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('card «Teclas negras» sobre hero', () {
      expect(
        contrastRatio(DesignTokens.onHero, DesignTokens.hero),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(DesignTokens.speedAccentOnDark, DesignTokens.hero),
        greaterThanOrEqualTo(3),
      );
    });
  });

  testWidgets('SpeedGameScreen usa el tema oscuro de sesión', (tester) async {
    await tester.pumpWidget(
      wrap(const SpeedGameScreen(targetMode: GameMode.singleNote)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Listo para el desafío'), findsOneWidget);
    final context = tester.element(find.text('Listo para el desafío'));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, DesignTokens.sessionBackground);
    expect(
      TogescColors.of(context).speedAccent,
      DesignTokens.speedAccentOnDark,
    );
  });

  testWidgets('selector de velocidad muestra los 5 modos y la dificultad', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const SpeedModeSelectScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(SpeedModeOptionCard), findsNWidgets(5));
    expect(find.text('TIEMPO INICIAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Lote 6 · selección', () {
    Future<void> pumpSelect(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrap(const SpeedModeSelectScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('tarjetas radio con la mejor racha guardada o «—»', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        speedBestStreakKey(SpeedDifficulty.pro): 4,
      });
      final handle = tester.ensureSemantics();
      await pumpSelect(tester);

      expect(find.byType(SpeedDifficultyCard), findsNWidgets(3));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('speed-best-pro'))).data,
        '4',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('speed-best-easy'))).data,
        '—',
      );
      expect(
        find.bySemanticsLabel(
          'Pro, 10 segundos. Ritmo de práctica habitual. Mejor racha: 4',
        ),
        findsOneWidget,
      );

      bool checked(String id) =>
          tester
              .getSemantics(find.byKey(ValueKey('speed-diff-$id')))
              .getSemanticsData()
              .flagsCollection
              .isChecked ==
          CheckedState.isTrue;

      expect(checked('pro'), isTrue);
      await tester.tap(find.byKey(const ValueKey('speed-diff-elite')));
      await tester.pumpAndSettle();
      expect(checked('elite'), isTrue);
      expect(checked('pro'), isFalse);
      handle.dispose();
    });

    testWidgets('«Cómo funciona» con 3 pasos y las reglas actuales', (
      tester,
    ) async {
      await pumpSelect(tester);
      expect(find.byKey(const ValueKey('speed-how')), findsOneWidget);
      expect(SpeedHowItWorksCard.steps, hasLength(3));
      expect(
        SpeedHowItWorksCard.steps[1],
        'Cada acierto reduce el tiempo límite 1 s, hasta un mínimo de 3 s.',
      );
      expect(find.text('Teclas negras'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('formatSpeedSeconds usa coma y quita ceros', () {
      expect(formatSpeedSeconds(3), '3 s');
      expect(formatSpeedSeconds(1.5), '1,5 s');
      expect(formatSpeedSeconds(0.925, decimals: 2), '0,93 s');
    });
  });

  group('Lote 6 · juego', () {
    testWidgets('cuenta atrás 3-2-1, destello y récord personal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        wrap(const SpeedGameScreen(targetMode: GameMode.singleNote)),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SpeedGameScreen)),
      );
      await container.read(srsSystemProvider.future);

      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      expect(find.byKey(const ValueKey('speed-countdown-3')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(const ValueKey('speed-countdown-2')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(const ValueKey('speed-countdown-1')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 400));

      SpeedSessionState session() => container.read(speedSessionProvider);
      expect(session().state, SpeedState.waitingForAnswer);
      expect(find.byKey(const ValueKey('speed-timer')), findsOneWidget);

      // Acierto: destello verde y racha 1.
      container
          .read(speedSessionProvider.notifier)
          .submitAnswer(session().currentNotes, 0.8);
      await tester.pump();
      expect(find.byKey(const ValueKey('speed-flash')), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(session().state, SpeedState.waitingForAnswer);

      // Fallo: cierra la ráfaga con récord (sin racha previa en Pro).
      final wrong = session().currentNotes.first == 'C' ? 'D' : 'C';
      container.read(speedSessionProvider.notifier).submitAnswer([wrong], 1.2);
      await tester.pumpAndSettle();

      expect(find.text('Incorrecto'), findsOneWidget);
      expect(find.byKey(const ValueKey('speed-new-record')), findsOneWidget);
      expect(find.text('Nuevo récord personal'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('speed-kpi-streak')))
            .data,
        '1',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('speed-kpi-answers')))
            .data,
        '1/2',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('speed-kpi-best'))).data,
        '0,80 s',
      );
      expect(
        container.read(speedBestStreakProvider).value?[SpeedDifficulty.pro],
        1,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(speedBestStreakKey(SpeedDifficulty.pro)), 1);

      // Reintentar vuelve a la cuenta atrás y quita la píldora.
      await tester.tap(find.byKey(const ValueKey('speed-retry')));
      await tester.pump();
      // Deja terminar el fundido del AnimatedSwitcher (sigue en el «3»).
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('speed-countdown-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('speed-new-record')), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      container.read(speedSessionProvider.notifier).reset();
      await tester.pumpAndSettle();
    });

    testWidgets('sin superar la mejor racha no hay píldora', (tester) async {
      SharedPreferences.setMockInitialValues({
        speedBestStreakKey(SpeedDifficulty.pro): 5,
      });
      await tester.pumpWidget(
        wrap(const SpeedGameScreen(targetMode: GameMode.singleNote)),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SpeedGameScreen)),
      );
      await container.read(srsSystemProvider.future);
      await container.read(speedSessionProvider.notifier).startRound();
      await tester.pump();
      final notes = container.read(speedSessionProvider).currentNotes;
      container.read(speedSessionProvider.notifier).submitAnswer([
        notes.first == 'C' ? 'D' : 'C',
      ], 1);
      await tester.pumpAndSettle();
      expect(find.text('Incorrecto'), findsOneWidget);
      expect(find.byKey(const ValueKey('speed-new-record')), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('speed-kpi-answers')))
            .data,
        '0/1',
      );
    });

    testWidgets('movimiento reducido: cuenta atrás de 500 ms y sin destello', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressRepositoryProvider.overrideWithValue(repo),
            srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
            audioPlayerServiceProvider.overrideWithValue(_SilentAudio()),
            audioGeneratorProvider.overrideWithValue(
              AudioGenerator(random: Random(42)),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const SpeedGameScreen(targetMode: GameMode.singleNote),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SpeedGameScreen)),
      );
      await container.read(srsSystemProvider.future);
      await tester.tap(find.text('Comenzar'));
      await tester.pump();
      expect(find.byKey(const ValueKey('speed-countdown-3')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('speed-countdown-2')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 400));

      final notes = container.read(speedSessionProvider).currentNotes;
      container.read(speedSessionProvider.notifier).submitAnswer(notes, 1);
      await tester.pump();
      expect(find.byKey(const ValueKey('speed-flash')), findsNothing);
      container.read(speedSessionProvider.notifier).reset();
      await tester.pumpAndSettle();
    });
  });

  group('Lote 6 · temporizador en anillo', () {
    Future<void> pumpTimer(
      WidgetTester tester,
      double remaining, {
      bool reduced = false,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.session,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              body: Center(
                child: CountdownTimerWidget(
                  remainingTime: remaining,
                  totalTime: 10,
                ),
              ),
            ),
          ),
        ),
      );
    }

    double beatScale(WidgetTester tester) => tester
        .widget<ScaleTransition>(
          find.ancestor(
            of: find.byKey(const ValueKey('speed-timer-value')),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    test('estado bajo: < 2 s o < 30 % del límite', () {
      expect(CountdownTimerWidget.isLow(1.9, 5), isTrue);
      expect(CountdownTimerWidget.isLow(2.9, 10), isTrue);
      expect(CountdownTimerWidget.isLow(3.5, 10), isFalse);
      expect(CountdownTimerWidget.isLow(4, 15), isTrue);
    });

    testWidgets('168 px, acento normal y #EF9A9A con «¡Rápido!» en bajo', (
      tester,
    ) async {
      await pumpTimer(tester, 6.4);
      expect(
        tester.getSize(find.byKey(const ValueKey('speed-timer'))),
        const Size.square(168),
      );
      expect(find.text('6,4'), findsOneWidget);
      expect(find.text('segundos'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Tiempo restante: 7 segundos'),
        findsOneWidget,
      );

      await pumpTimer(tester, 1.5, reduced: true);
      expect(find.text('¡Rápido!'), findsOneWidget);
      final value = tester.widget<Text>(
        find.byKey(const ValueKey('speed-timer-value')),
      );
      expect(value.style?.color, DesignTokens.sessionError);
      // Sin latido con movimiento reducido: la cifra no escala.
      await tester.pump(const Duration(milliseconds: 250));
      expect(beatScale(tester), 1);
    });

    testWidgets('el latido en estado bajo se detiene al salir', (tester) async {
      await pumpTimer(tester, 1.5);
      await tester.pump(const Duration(milliseconds: 250));
      expect(beatScale(tester), greaterThan(1));
      await pumpTimer(tester, 8);
      // Sin latido infinito: pumpAndSettle termina.
      await tester.pumpAndSettle();
      expect(beatScale(tester), 1);
    });
  });

  testWidgets('resumen: KPI con coma decimal y cifras tabulares', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.session,
        home: const Scaffold(
          body: SpeedSessionSummaryCard(
            streak: 3,
            bestTime: 0.9,
            averageTime: 1.5,
            correctRounds: 3,
            roundsPlayed: 4,
          ),
        ),
      ),
    );
    expect(find.text('Racha final'), findsOneWidget);
    expect(find.text('0,90 s'), findsOneWidget);
    expect(find.text('1,50 s'), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);
    final value = tester.widget<Text>(find.text('1,50 s'));
    expect(
      value.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('Reintentar usa el acento de velocidad con texto onSpeedAccent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.session,
        home: Scaffold(
          body: SpeedSessionRetryActions(onRetry: () {}, onMenu: () {}),
        ),
      ),
    );
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('speed-retry')),
    );
    final style = button.style!;
    expect(style.backgroundColor?.resolve({}), DesignTokens.speedAccentOnDark);
    expect(style.foregroundColor?.resolve({}), DesignTokens.hero);
    expect(
      tester.getSize(find.byKey(const ValueKey('speed-menu'))).height,
      greaterThanOrEqualTo(48),
    );
  });
}
