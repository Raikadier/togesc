import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/game_session_provider.dart';
import 'package:togesc/providers/practice_focus_provider.dart';
import 'package:togesc/providers/session_history_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/screens/game_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/widgets/piano_keyboard.dart';

class _FakeSRSNotifier extends AsyncNotifier<SRSSystem>
    implements SRSNotifier {
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

void main() {
  late ProviderContainer container;

  Future<void> setUpContainer({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues({
      clusterEnabledKey: false,
      ...prefs,
    });
    final srs = SRSSystem(
      repository: InMemoryProgressRepository(),
      random: Random(42),
      clock: () => DateTime(2026, 1, 1),
    );
    await srs.loadProgress();
    container = ProviderContainer(
      overrides: [
        progressRepositoryProvider
            .overrideWithValue(InMemoryProgressRepository()),
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        audioPlayerServiceProvider.overrideWithValue(
          AudioPlayerService(generator: AudioGenerator(random: Random(42))),
        ),
        audioGeneratorProvider
            .overrideWithValue(AudioGenerator(random: Random(42))),
      ],
    );
    await container.read(srsSystemProvider.future);
    // Ronda determinista: la sesión solo pregunta «D».
    container.read(practiceFocusNoteProvider.notifier).state = 'D';
  }

  tearDown(() => container.dispose());

  Widget buildApp({bool? autoStart = true}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: GameScreen(mode: GameMode.singleNote, autoStart: autoStart),
      ),
    );
  }

  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    const step = Duration(milliseconds: 100);
    var elapsed = Duration.zero;
    while (elapsed < total) {
      await tester.pump(step);
      elapsed += step;
    }
  }

  /// Monta la pantalla en móvil (390×844) y llega a `answer`.
  Future<void> pumpToAnswer(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp());
    await pumpFor(tester, const Duration(milliseconds: 2000));
    expect(find.text('RESPONDE'), findsOneWidget);
  }

  SemanticsNode keySemantics(WidgetTester tester, String label) {
    return tester.getSemantics(
      find.descendant(
        of: find.byType(PianoKeyboard),
        matching: find.bySemanticsLabel(label),
      ),
    );
  }

  group('GameScreen v2 · fases', () {
    testWidgets('«Preparado» siempre al entrar y «Estoy listo» arranca',
        (tester) async {
      await setUpContainer();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildApp(autoStart: null));
      await tester.pump();

      expect(find.text('PREPARADO'), findsOneWidget);
      expect(find.text('Ponte los auriculares'), findsOneWidget);
      expect(find.text('12 rondas · 1 nota · foco en D'), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
      expect(find.byKey(const ValueKey('session-test-sound')), findsOneWidget);
      // Teclado y controles ocultos hasta empezar.
      expect(find.byType(PianoKeyboard), findsNothing);
      expect(find.text('Repetir'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('session-start')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      expect(find.byType(PianoKeyboard), findsOneWidget);

      await pumpFor(tester, const Duration(milliseconds: 1800));
      expect(find.text('RESPONDE'), findsOneWidget);
      expect(find.text('¿Qué nota escuchaste?'), findsOneWidget);
      expect(
        find.text('Toca la tecla — se envía al instante, sin confirmar.'),
        findsOneWidget,
      );
    });

    testWidgets('Espacio arranca desde «Preparado»', (tester) async {
      await setUpContainer();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildApp(autoStart: null));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 1800));
      expect(find.text('RESPONDE'), findsOneWidget);
    });

    testWidgets('«Probar el sonido» suena sin empezar la sesión',
        (tester) async {
      await setUpContainer();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildApp(autoStart: null));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('session-test-sound')));
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.text('PREPARADO'), findsOneWidget);
      expect(
        find.textContaining(RegExp('La 4 \\(440 Hz\\)|No se pudo')),
        findsOneWidget,
      );
      expect(container.read(gameSessionProvider).roundsCompleted, 0);
      await pumpFor(tester, const Duration(seconds: 5));
    });

    testWidgets('barra superior: chips de ronda, precisión y racha',
        (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      expect(find.text('1 / 12'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.byKey(const ValueKey('session-progress')), findsOneWidget);
      expect(find.text('Repetir'), findsOneWidget);
      expect(find.text('Saltar'), findsOneWidget);
      expect(find.text('Toca la tecla que escuchaste'), findsOneWidget);
      // Un solo teclado, en la variante de sesión; sin TextField (D6).
      expect(find.byType(PianoKeyboard), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('piano-session-container')))
            .height,
        230,
      );
    });
  });

  group('GameScreen v2 · resultado sobre la tecla', () {
    testWidgets('acierto: un toque envía y la tecla queda en verde',
        (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      await tester.tap(find.text('D'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CORRECTO'), findsOneWidget);
      expect(find.text('Bien identificada'), findsOneWidget);
      expect(find.text('Siguiente ronda en un momento…'), findsOneWidget);
      expect(keySemantics(tester, 'D').hint, 'correcta');
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
      // Píldora SRS de la nota.
      expect(find.byKey(const ValueKey('srs-pill-D')), findsOneWidget);
      expect(find.textContaining('SRS 0/5 →'), findsOneWidget);
      // Chips actualizadas.
      expect(find.text('100%'), findsOneWidget);
      expect(container.read(gameSessionProvider).currentStreak, 1);
    });

    testWidgets('fallo: «Era X, respondiste Y», correcta en verde y '
        'errónea en rojo', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      await tester.tap(find.text('E'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('INCORRECTO'), findsOneWidget);
      expect(find.text('Era D, respondiste E'), findsOneWidget);
      expect(
        find.text('La tecla correcta queda marcada en verde.'),
        findsOneWidget,
      );
      // Regresión game_screen.dart:145/521: la errónea se pinta desde
      // lastResult.wrongNotes, no desde la selección ya vaciada.
      expect(keySemantics(tester, 'D').hint, 'correcta');
      expect(keySemantics(tester, 'E').hint, 'incorrecta');
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      final piano = tester.widget<PianoKeyboard>(find.byType(PianoKeyboard));
      expect(piano.correctNotes, {'D'});
      expect(piano.incorrectNotes, {'E'});
      expect(piano.dimOthers, isTrue);
      expect(piano.disabled, isTrue);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('el resultado se anuncia en una región viva', (tester) async {
      await setUpContainer();
      final handle = tester.ensureSemantics();
      await pumpToAnswer(tester);

      await tester.tap(find.text('E'));
      await tester.pump(const Duration(milliseconds: 100));

      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Incorrecto\. Era D, respondiste E')),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('avance automático a los 2,2 s', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      await tester.tap(find.text('D'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CORRECTO'), findsOneWidget);

      await pumpFor(tester, const Duration(milliseconds: 1900));
      expect(find.text('CORRECTO'), findsOneWidget);

      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(find.text('CORRECTO'), findsNothing);
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      expect(find.text('2 / 12'), findsOneWidget);

      await pumpFor(tester, const Duration(milliseconds: 1800));
      expect(find.text('RESPONDE'), findsOneWidget);
    });

    testWidgets('modo manual (Ajustes): no avanza solo y ofrece «Siguiente '
        'ronda»', (tester) async {
      await setUpContainer(prefs: {autoAdvanceAfterResultV2Key: false});
      await pumpToAnswer(tester);

      await tester.tap(find.text('D'));
      await tester.pump(const Duration(milliseconds: 100));
      await pumpFor(tester, const Duration(milliseconds: 4000));
      expect(find.text('CORRECTO'), findsOneWidget);

      await tester.tap(find.text('Siguiente ronda'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 1800));
    });

    testWidgets('modo confirmar (Ajustes): el toque selecciona y '
        '«Confirmar» envía', (tester) async {
      await setUpContainer(prefs: {confirmBeforeSubmitV2Key: true});
      await pumpToAnswer(tester);

      expect(find.text('Toca la tecla y pulsa Confirmar.'), findsOneWidget);
      await tester.tap(find.text('D'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('RESPONDE'), findsOneWidget);
      expect(keySemantics(tester, 'D').hint, 'seleccionada');

      await tester.tap(find.text('Confirmar'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CORRECTO'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 4500));
    });

    testWidgets('Repetir vuelve a listen con la misma ronda', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);
      final notes = container.read(gameSessionProvider).currentNotes;

      await tester.tap(find.text('Repetir'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 1800));
      expect(find.text('RESPONDE'), findsOneWidget);
      expect(container.read(gameSessionProvider).currentNotes, notes);
      expect(container.read(gameSessionProvider).roundsCompleted, 0);
    });

    testWidgets('Saltar descarta la ronda y empieza otra', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      await tester.tap(find.text('Saltar'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 1800));
      expect(find.text('RESPONDE'), findsOneWidget);
      expect(container.read(gameSessionProvider).roundsCompleted, 0);
    });
  });

  group('GameScreen v2 · atajos de teclado', () {
    testWidgets('letra A–G responde la nota natural', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CORRECTO'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 4200));
    });

    testWidgets('⇧ + letra responde el sostenido', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Era D, respondiste C#'), findsOneWidget);
      expect(keySemantics(tester, 'C#').hint, 'incorrecta');
      await pumpFor(tester, const Duration(milliseconds: 4200));
    });

    testWidgets('R repite y Espacio salta la espera del resultado',
        (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 1800));
      expect(find.text('RESPONDE'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CORRECTO'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CORRECTO'), findsNothing);
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      expect(find.text('2 / 12'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 1800));
    });

    testWidgets('con un campo de texto enfocado los atajos no actúan',
        (tester) async {
      await setUpContainer(prefs: {gameInputModeV2Key: 'both'});
      await pumpToAnswer(tester);

      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('RESPONDE'), findsOneWidget);
      expect(container.read(gameSessionProvider).roundsCompleted, 0);
    });
  });

  group('GameScreen v2.1 · pausa, racha y resumen', () {
    Future<void> answerRound(WidgetTester tester, String note) async {
      expect(find.text('RESPONDE'), findsOneWidget);
      await tester.tap(find.text(note));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('Pausar abre la hoja y «Continuar» reanuda', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-pause-sheet')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('session-pause-sheet')),
          matching: find.text('Sesión en pausa'),
        ),
        findsOneWidget,
      );
      expect(find.text('Ronda 1 de 12 · 0 aciertos'), findsOneWidget);
      expect(container.read(gameSessionProvider).isPaused, isTrue);

      await tester.tap(find.byKey(const ValueKey('session-pause-resume')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-pause-sheet')), findsNothing);
      expect(container.read(gameSessionProvider).isPaused, isFalse);
      expect(find.text('RESPONDE'), findsOneWidget);
    });

    testWidgets('Esc pausa y «Reiniciar» vuelve a «Preparado»', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);
      await answerRound(tester, 'D');
      expect(container.read(gameSessionProvider).roundsCompleted, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Ronda 1 de 12 · 1 acierto'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('session-pause-restart')));
      await tester.pumpAndSettle();
      expect(find.text('PREPARADO'), findsOneWidget);
      expect(find.byType(PianoKeyboard), findsNothing);
      final session = container.read(gameSessionProvider);
      expect(session.roundsCompleted, 0);
      expect(session.srsSnapshot, isNull);
    });

    testWidgets('volver con la sesión en curso pausa; «Salir sin guardar» '
        'sale sin registrar la sesión', (tester) async {
      await setUpContainer();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GameScreen(
                        mode: GameMode.singleNote,
                        autoStart: true,
                      ),
                    ),
                  ),
                  child: const Text('ABRIR'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ABRIR'));
      await pumpFor(tester, const Duration(milliseconds: 2400));
      await answerRound(tester, 'D');

      // El gesto de volver no sale: abre la pausa.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-pause-sheet')), findsOneWidget);
      expect(find.byType(GameScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('session-pause-exit')));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('ABRIR'), findsOneWidget);
      await tester.pump();
      final history =
          await container.read(sessionHistoryProvider.future);
      expect(history, isEmpty);
    });

    testWidgets('con 3 aciertos seguidos: «¡3 seguidas!»', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester);
      for (var round = 1; round <= 3; round++) {
        await answerRound(tester, 'D');
        if (round < 3) {
          expect(find.text('¡$round seguidas!'), findsNothing);
          await pumpFor(tester, const Duration(milliseconds: 2400));
          await pumpFor(tester, const Duration(milliseconds: 1800));
        }
      }
      expect(find.text('¡3 seguidas!'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 2400));
    });

    testWidgets('meta cumplida: resumen con medalla, KPI y cambios SRS',
        (tester) async {
      await setUpContainer(prefs: {sessionRoundGoalV2Key: 5});
      final handle = tester.ensureSemantics();
      await pumpToAnswer(tester);
      final before = container.read(gameSessionProvider).srsSnapshot;
      expect(before, isNotNull);
      expect(before!['D']!.timesSeen, 0);

      for (var round = 1; round <= 5; round++) {
        await answerRound(tester, 'D');
        await pumpFor(tester, const Duration(milliseconds: 2400));
        if (round < 5) await pumpFor(tester, const Duration(milliseconds: 1800));
      }

      expect(find.byKey(const ValueKey('session-summary')), findsOneWidget);
      expect(find.text('SESIÓN COMPLETADA'), findsOneWidget);
      expect(find.text('Gran oído hoy'), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 1));
      expect(find.text('100 %'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
      final session = container.read(gameSessionProvider);
      expect(session.responseTimes, hasLength(5));
      expect(session.meanResponseTimeSec, isNotNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('session-summary-latency')),
          matching: find.text('—'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('session-summary-change-D')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^D: nivel 0 a [1-5] de 5, sube$')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ear-map')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Sesión completada\. Gran oído hoy')),
        findsOneWidget,
      );
      expect(find.text('Volver al inicio'), findsOneWidget);
      expect(find.text('Ver mi progreso'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('modo manual: «Ver resumen» al cumplir la meta',
        (tester) async {
      await setUpContainer(prefs: {
        sessionRoundGoalV2Key: 5,
        autoAdvanceAfterResultV2Key: false,
      });
      await pumpToAnswer(tester);
      for (var round = 1; round <= 5; round++) {
        await answerRound(tester, 'D');
        if (round < 5) {
          await tester.tap(find.text('Siguiente ronda'));
          await tester.pump(const Duration(milliseconds: 100));
          await pumpFor(tester, const Duration(milliseconds: 1800));
        }
      }
      await pumpFor(tester, const Duration(seconds: 4));
      expect(find.byKey(const ValueKey('session-summary')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('session-show-summary')));
      await tester.pump();
      expect(find.byKey(const ValueKey('session-summary')), findsOneWidget);
      await pumpFor(tester, const Duration(seconds: 2));
    });
  });

  group('GameScreen v2 · escritorio (1d)', () {
    testWidgets('≥1024: anillo, panel «Enfoque SRS» y teclado ancho',
        (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester, size: const Size(1280, 800));

      expect(find.text(GameMode.singleNote.displayName), findsOneWidget);
      expect(find.text('Ronda 1 / 12'), findsOneWidget);
      expect(find.text('Pausar'), findsOneWidget);
      expect(find.textContaining('Esc pausar'), findsOneWidget);
      expect(find.byKey(const ValueKey('session-srs-panel')), findsOneWidget);
      expect(find.text('ENFOQUE SRS DE LA SESIÓN'), findsOneWidget);
      // La nota foco de la sesión, sin datos todavía.
      expect(find.text('Sin datos'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('session-shortcuts-legend')),
        findsOneWidget,
      );
      final piano = tester.widget<PianoKeyboard>(find.byType(PianoKeyboard));
      expect(piano.variant, PianoKeyboardVariant.sessionWide);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('piano-session-container')))
            .height,
        210,
      );
      expect(tester.getSize(find.byKey(const ValueKey('piano-key-C#'))),
          const Size(52, 126));
      expect(tester.takeException(), isNull);
    });

    testWidgets('el panel «Enfoque SRS» se actualiza en vivo tras cada ronda '
        '(SRSNotifier real)', (tester) async {
      // Sin override de srsSystemProvider: el notifier real carga el SRS
      // desde un repositorio en memoria y la sesión lo muta en el sitio.
      SharedPreferences.setMockInitialValues({clusterEnabledKey: false});
      container = ProviderContainer(
        overrides: [
          progressRepositoryProvider
              .overrideWithValue(InMemoryProgressRepository()),
          audioPlayerServiceProvider.overrideWithValue(
            AudioPlayerService(generator: AudioGenerator(random: Random(42))),
          ),
          audioGeneratorProvider
              .overrideWithValue(AudioGenerator(random: Random(42))),
        ],
      );
      await container.read(srsSystemProvider.future);
      container.read(practiceFocusNoteProvider.notifier).state = 'D';
      final handle = tester.ensureSemantics();
      await pumpToAnswer(tester, size: const Size(1280, 800));

      Finder row(String label) =>
          find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}'));
      expect(row('D, Sin datos, sin datos de precisión, nivel SRS 0 de 5'),
          findsOneWidget);

      // Ronda 1: acierto → En curso, 100 %, nivel 0 (1 acierto de 5).
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CORRECTO'), findsOneWidget);
      expect(find.text('Sin datos'), findsNothing);
      expect(row('D, En curso, 100 por ciento, nivel SRS 0 de 5'),
          findsOneWidget);

      // Ronda 2: segundo acierto seguido → nivel 1.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpFor(tester, const Duration(milliseconds: 1900));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 100));
      expect(row('D, En curso, 100 por ciento, nivel SRS 1 de 5'),
          findsOneWidget);

      // Ronda 3: fallo → 67 %, la racha vuelve a 0.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpFor(tester, const Duration(milliseconds: 1900));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('INCORRECTO'), findsOneWidget);
      expect(row('D, En curso, 67 por ciento, nivel SRS 0 de 5'),
          findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 2400));
      handle.dispose();
    });

    testWidgets('<1024 usa el layout móvil sin panel', (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester, size: const Size(800, 900));

      expect(find.byKey(const ValueKey('session-srs-panel')), findsNothing);
      final piano = tester.widget<PianoKeyboard>(find.byType(PianoKeyboard));
      expect(piano.variant, PianoKeyboardVariant.session);
    });
  });
}
