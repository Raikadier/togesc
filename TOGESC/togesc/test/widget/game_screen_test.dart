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
    testWidgets('sin gesto previo muestra el idle mínimo (D4)', (tester) async {
      await setUpContainer();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildApp(autoStart: false));
      await tester.pump();

      expect(find.text('Toca para empezar'), findsOneWidget);
      expect(find.text('Empezar'), findsOneWidget);

      await tester.tap(find.text('Empezar'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      expect(find.text('Escucha con atención'), findsOneWidget);

      await pumpFor(tester, const Duration(milliseconds: 1800));
      expect(find.text('RESPONDE'), findsOneWidget);
      expect(find.text('¿Qué nota escuchaste?'), findsOneWidget);
      expect(
        find.text('Toca la tecla — se envía al instante, sin confirmar.'),
        findsOneWidget,
      );
    });

    testWidgets('con gesto previo entra directo a listen, sin idle',
        (tester) async {
      await setUpContainer();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildApp(autoStart: null));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Toca para empezar'), findsNothing);
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      // listen dura al menos 1,5 s.
      await pumpFor(tester, const Duration(milliseconds: 1000));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('RESPONDE'), findsOneWidget);
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

  group('GameScreen v2 · escritorio (1d)', () {
    testWidgets('≥1024: anillo, panel «Enfoque SRS» y teclado ancho',
        (tester) async {
      await setUpContainer();
      await pumpToAnswer(tester, size: const Size(1280, 800));

      expect(find.text(GameMode.singleNote.displayName), findsOneWidget);
      expect(find.text('Ronda 1 / 12'), findsOneWidget);
      expect(find.text('Pausar'), findsOneWidget);
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
