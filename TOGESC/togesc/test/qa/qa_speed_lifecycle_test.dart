import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/session_history_provider.dart';
import 'package:togesc/providers/speed_session_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/screens/speed_game_screen.dart';
import 'package:togesc/services/srs_system.dart';

import 'qa_support.dart';

/// Velocidad a nivel de pantalla: entrar, jugar, salir (pop) y volver.
///
/// `speedSessionProvider` no es autoDispose: sobrevive a la pantalla, así que
/// el ciclo de vida (`deactivate` → `stop`, `setTargetMode` al entrar) es lo
/// único que garantiza un estado limpio.
void main() {
  late ProviderContainer container;
  late SRSSystem srs;

  Future<void> pumpHost(WidgetTester tester) async {
    final (overrides, loaded) = await qaGameOverrides(silentAudio: true);
    srs = loaded;
    container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await container.read(srsSystemProvider.future);
    qaSetViewSize(tester, const Size(420, 1400));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SpeedGameScreen(
                        targetMode: GameMode.singleNote,
                      ),
                    ),
                  ),
                  child: const Text('ABRIR'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  SpeedSessionState session() => container.read(speedSessionProvider);

  Future<void> enter(WidgetTester tester) async {
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
    expect(find.byType(SpeedGameScreen), findsOneWidget);
  }

  Future<void> exit(WidgetTester tester) async {
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(SpeedGameScreen), findsNothing);
  }

  /// Cuenta atrás 3-2-1 (800 ms por cifra) hasta la espera de respuesta.
  Future<void> startBurst(WidgetTester tester) async {
    await tester.tap(find.text('Comenzar'));
    await qaPumpFor(tester, const Duration(milliseconds: 2800));
    expect(session().state, SpeedState.waitingForAnswer);
  }

  /// Responde por la UI: toca la tecla correcta (o una errónea) y «Confirmar».
  Future<void> answer(WidgetTester tester, {required bool correct}) async {
    final target = session().currentNotes.single;
    final note = correct ? target : (target == 'C' ? 'D' : 'C');
    final rect = tester.getRect(find.byKey(ValueKey('piano-key-$note')));
    await tester.tapAt(
      note.contains('#')
          ? rect.center
          : rect.bottomCenter - const Offset(0, 16),
    );
    await tester.pump();
    final confirm = find.widgetWithText(FilledButton, 'Confirmar');
    await tester.ensureVisible(confirm);
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
  }

  Future<List<int>> historyRounds() async {
    final history = await container.read(sessionHistoryProvider.future);
    return [
      for (final h in history)
        if (h.kind == PracticeKind.speed) h.roundsCompleted,
    ];
  }

  int totalSeen() => srs.noteData.values.fold(0, (sum, d) => sum + d.timesSeen);

  testWidgets('jugar una ronda, salir y volver: estado limpio e historial '
      'registrado una sola vez', (tester) async {
    await pumpHost(tester);
    await enter(tester);
    await startBurst(tester);
    await answer(tester, correct: true);
    expect(session().state, SpeedState.correct);
    expect(session().roundsPlayed, 1);

    await exit(tester);
    expect(await historyRounds(), [1]);

    await enter(tester);
    expect(session().state, SpeedState.idle);
    expect(session().roundsPlayed, 0);
    expect(session().consecutiveCorrect, 0);
    expect(session().responseTimes, isEmpty);
    expect(find.text('Comenzar'), findsOneWidget);

    // Salir sin jugar no añade nada.
    await exit(tester);
    expect(await historyRounds(), [1]);
  });

  testWidgets('al volver a entrar, el primer frame no muestra el resultado '
      'de la visita anterior', (tester) async {
    await pumpHost(tester);
    await enter(tester);
    await startBurst(tester);
    await answer(tester, correct: true);
    await exit(tester);

    await tester.tap(find.text('ABRIR'));
    await tester.pump();
    expect(find.text('Correcto'), findsNothing);
    expect(find.text('Siguiente'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('las rondas de una ráfaga cerrada con «Reintentar» quedan en el '
      'historial al salir [BUG: speed_session_provider.dart:299-311 retry() '
      'pone roundsPlayed a 0 sin registrar la ráfaga; speed_game_screen.dart:'
      '149 solo registra la última]', (tester) async {
    await pumpHost(tester);
    await enter(tester);
    await startBurst(tester);
    await answer(tester, correct: true);
    await tester.tap(find.text('Siguiente'));
    await qaPumpFor(tester, const Duration(milliseconds: 400));
    expect(session().state, SpeedState.waitingForAnswer);
    await answer(tester, correct: false);
    expect(session().state, SpeedState.incorrect);
    expect(session().roundsPlayed, 2);

    // Nueva ráfaga y un acierto más.
    await tester.tap(find.byKey(const ValueKey('speed-retry')));
    await qaPumpFor(tester, const Duration(milliseconds: 2800));
    expect(session().state, SpeedState.waitingForAnswer);
    await answer(tester, correct: true);

    await exit(tester);
    final rounds = await historyRounds();
    expect(
      rounds.fold<int>(0, (a, b) => a + b),
      3,
      reason: 'historial de velocidad: $rounds',
    );
  }, skip: qaSkipBug);

  for (final exitAt in const [
    Duration(milliseconds: 900), // en el «2»
    Duration(milliseconds: 2300), // en el «1», justo antes de arrancar
  ]) {
    testWidgets('salir con la cuenta atrás corriendo (${exitAt.inMilliseconds}'
        ' ms) no provoca timeout ni toca el SRS después', (tester) async {
      await pumpHost(tester);
      await enter(tester);
      await tester.tap(find.text('Comenzar'));
      await qaPumpFor(tester, exitAt);
      expect(find.byType(SpeedGameScreen), findsOneWidget);

      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      // Más que el tiempo límite más largo (15 s) más la cuenta atrás.
      await qaPumpFor(tester, const Duration(seconds: 20));

      expect(find.byType(SpeedGameScreen), findsNothing);
      expect(tester.takeException(), isNull);
      expect(session().state, isNot(SpeedState.timeout));
      expect(session().roundsPlayed, 0);
      expect(totalSeen(), 0, reason: 'el SRS no debe penalizar nada');
      expect(await historyRounds(), isEmpty);
    });
  }

  testWidgets('salir en el «1» no arranca la ronda ni suena una nota tras '
      'salir [BUG: speed_game_screen.dart:112-133 el Timer de la cuenta atrás '
      'solo se cancela en dispose (l.83); durante la transición de salida '
      'sigue mounted y llama a _startRound]', (tester) async {
    await pumpHost(tester);
    final audio = container.read(audioPlayerServiceProvider) as QaSilentAudio;
    await enter(tester);
    await tester.tap(find.text('Comenzar'));
    await qaPumpFor(tester, const Duration(milliseconds: 2300));
    final playsAtExit = audio.plays;

    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await qaPumpFor(tester, const Duration(seconds: 3));

    expect(find.byType(SpeedGameScreen), findsNothing);
    expect(audio.plays, playsAtExit, reason: 'sonidos tras salir');
    expect(session().state, SpeedState.idle);
    expect(session().currentNotes, isEmpty);
  }, skip: qaSkipBug);

  testWidgets('salir con la respuesta pendiente no provoca timeout después', (
    tester,
  ) async {
    await pumpHost(tester);
    await enter(tester);
    await startBurst(tester);
    await exit(tester);
    await qaPumpFor(tester, const Duration(seconds: 20));

    expect(tester.takeException(), isNull);
    expect(session().state, isNot(SpeedState.timeout));
    expect(totalSeen(), 0);
    expect(await historyRounds(), isEmpty);
  });
}
