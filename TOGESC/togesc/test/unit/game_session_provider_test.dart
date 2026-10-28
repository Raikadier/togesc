import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/game_session_provider.dart';
import 'package:togesc/providers/practice_focus_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

void main() {
  late ProviderContainer container;
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

    container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repo),
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        audioPlayerServiceProvider.overrideWithValue(
          AudioPlayerService(generator: AudioGenerator(random: Random(42))),
        ),
        audioGeneratorProvider.overrideWithValue(
          AudioGenerator(random: Random(42)),
        ),
        // Toda ronda con foco es ronda de foco (determinista).
        practiceFocusRandomProvider.overrideWithValue(_FixedRandom(0.0)),
      ],
    );

    // Esperar a que el SRS se cargue
    await container.read(srsSystemProvider.future);
  });

  tearDown(() {
    container.dispose();
  });

  group('GameSessionNotifier', () {
    test('estado inicial es idle con singleNote', () {
      final state = container.read(gameSessionProvider);
      expect(state.state, GameState.idle);
      expect(state.mode, GameMode.singleNote);
      expect(state.currentNotes, isEmpty);
      expect(state.numNotes, 1);
      expect(state.sessionInstrumentOverride, isNull);
      expect(state.lastResult, isNull);
      expect(state.roundsCompleted, 0);
      expect(state.isPaused, isFalse);
      expect(state.goalReached, isFalse);
    });

    test('setMode cambia el modo y vuelve a idle', () {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setMode(GameMode.chord);

      final state = container.read(gameSessionProvider);
      expect(state.mode, GameMode.chord);
      expect(state.state, GameState.idle);
    });

    test('setSessionInstrumentOverride guarda override de sesion', () {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setSessionInstrumentOverride('piano');
      expect(
        container.read(gameSessionProvider).sessionInstrumentOverride,
        'piano',
      );

      notifier.setSessionInstrumentOverride(null);
      expect(
        container.read(gameSessionProvider).sessionInstrumentOverride,
        isNull,
      );
    });

    test('startRound selecciona notas y transiciona a waitingForAnswer', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      final state = container.read(gameSessionProvider);
      expect(state.state, GameState.waitingForAnswer);
      expect(state.currentNotes, isNotEmpty);
      expect(state.currentNotes.length, 1); // singleNote mode
      expect(state.numNotes, 1);
      expect(state.lastResult, isNull);
    });

    test('startRound en modo interval selecciona 2 notas', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setMode(GameMode.interval);
      await notifier.startRound();

      final state = container.read(gameSessionProvider);
      expect(state.currentNotes.length, 2);
      expect(state.numNotes, 2);
    });

    test('startRound en modo chord selecciona 3 notas', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setMode(GameMode.chord);
      await notifier.startRound();

      final state = container.read(gameSessionProvider);
      expect(state.currentNotes.length, 3);
      expect(state.numNotes, 3);
    });

    test('startRound en modo sharpsOnly selecciona nota sostenida', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setMode(GameMode.sharpsOnly);
      await notifier.startRound();

      final state = container.read(gameSessionProvider);
      expect(state.currentNotes.length, 1);
      expect(state.currentNotes.first, endsWith('#'));
    });

    test('submitAnswer correcta muestra resultado correcto', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      final notes = container.read(gameSessionProvider).currentNotes;
      await notifier.submitAnswer(notes, 1.5);

      final state = container.read(gameSessionProvider);
      expect(state.state, GameState.showingResult);
      expect(state.lastResult, isNotNull);
      expect(state.lastResult!.isCorrect, true);
      expect(state.lastResult!.correctNotes, notes.toSet());
      expect(state.lastResult!.responseTime, 1.5);
      expect(state.lastResult!.srsChanges, isNotEmpty);
      expect(state.roundsCompleted, 1);
    });

    test('skipRound vuelve a idle sin actualizar SRS', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();
      notifier.skipRound();

      final state = container.read(gameSessionProvider);
      expect(state.state, GameState.idle);
      expect(state.currentNotes, isEmpty);
      expect(state.roundsCompleted, 0);
    });

    test('pauseRound y resumeRound alternan isPaused', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      notifier.pauseRound();
      expect(container.read(gameSessionProvider).isPaused, isTrue);

      notifier.resumeRound();
      expect(container.read(gameSessionProvider).isPaused, isFalse);
    });

    test('submitAnswer incorrecta muestra resultado incorrecto', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      await notifier.submitAnswer(['X'], 2.0); // nota invalida no esta en SRS

      // Si la nota no coincide, isCorrect es false
      final state = container.read(gameSessionProvider);
      expect(state.state, GameState.showingResult);
      expect(state.lastResult!.isCorrect, false);
    });

    test('playCluster transiciona a playingCluster y luego idle', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();
      final notes = container.read(gameSessionProvider).currentNotes;
      await notifier.submitAnswer(notes, 1.0);

      await notifier.playCluster();

      final state = container.read(gameSessionProvider);
      expect(state.state, GameState.idle);
    });

    test('reset vuelve al estado inicial', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();
      notifier.reset();

      final state = container.read(gameSessionProvider);
      expect(state.state, GameState.idle);
      expect(state.currentNotes, isEmpty);
      expect(state.mode, GameMode.singleNote);
    });

    test('startRound con nota enfocada selecciona solo esa nota', () async {
      container.read(practiceFocusNoteProvider.notifier).state = 'E';
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      final state = container.read(gameSessionProvider);
      expect(state.currentNotes, ['E']);
    });

    test('flujo completo: startRound -> submitAnswer -> playCluster', () async {
      final notifier = container.read(gameSessionProvider.notifier);

      // 1. Iniciar ronda
      await notifier.startRound();
      expect(container.read(gameSessionProvider).state, GameState.waitingForAnswer);

      // 2. Responder correctamente
      final notes = container.read(gameSessionProvider).currentNotes;
      await notifier.submitAnswer(notes, 1.0);
      expect(container.read(gameSessionProvider).state, GameState.showingResult);
      expect(container.read(gameSessionProvider).lastResult!.isCorrect, true);

      // 3. Cluster de limpieza
      await notifier.playCluster();
      expect(container.read(gameSessionProvider).state, GameState.idle);
    });

    test('startRound en modo random selecciona entre 1 y 5 notas', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setMode(GameMode.random);
      await notifier.startRound();

      final state = container.read(gameSessionProvider);
      expect(state.numNotes, greaterThanOrEqualTo(randomMinNotes));
      expect(state.numNotes, lessThanOrEqualTo(randomMaxNotes));
      expect(state.currentNotes.length, state.numNotes);
    });

    test('RoundResult guarda las notas respondidas (fallo)', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      final correct = container.read(gameSessionProvider).currentNotes.first;
      final wrong = correct == 'C' ? 'D' : 'C';
      await notifier.submitAnswer([wrong], 1.0);

      final result = container.read(gameSessionProvider).lastResult!;
      expect(result.isCorrect, isFalse);
      expect(result.answerNotes, [wrong]);
      expect(result.wrongNotes, {wrong});
      expect(result.missedNotes, {correct});
    });

    test('RoundResult acierto no tiene notas erroneas', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      final notes = container.read(gameSessionProvider).currentNotes;
      await notifier.submitAnswer(notes, 1.0);

      final result = container.read(gameSessionProvider).lastResult!;
      expect(result.answerNotes, notes);
      expect(result.wrongNotes, isEmpty);
      expect(result.missedNotes, isEmpty);
    });

    test('racha de sesion sube con aciertos y vuelve a 0 con un fallo',
        () async {
      final notifier = container.read(gameSessionProvider.notifier);
      expect(container.read(gameSessionProvider).currentStreak, 0);

      for (var i = 0; i < 2; i++) {
        await notifier.startRound();
        final notes = container.read(gameSessionProvider).currentNotes;
        await notifier.submitAnswer(notes, 1.0);
      }
      expect(container.read(gameSessionProvider).currentStreak, 2);
      expect(container.read(gameSessionProvider).bestStreak, 2);
      expect(
        container.read(gameSessionProvider).sessionAccuracyPercent,
        closeTo(100, 0.001),
      );

      await notifier.startRound();
      final correct = container.read(gameSessionProvider).currentNotes.first;
      await notifier.submitAnswer([correct == 'C' ? 'D' : 'C'], 1.0);

      final state = container.read(gameSessionProvider);
      expect(state.currentStreak, 0);
      expect(state.bestStreak, 2);
      expect(state.sessionAccuracyPercent, closeTo(66.666, 0.01));

      notifier.setMode(GameMode.singleNote);
      expect(container.read(gameSessionProvider).currentStreak, 0);
      expect(container.read(gameSessionProvider).bestStreak, 0);
      expect(
        container.read(gameSessionProvider).sessionAccuracyPercent,
        isNull,
      );
    });

    test('notas de foco de la sesion de hoy se priorizan', () async {
      container.read(practiceFocusNotesProvider.notifier).state =
          const ['E', 'G', 'A'];
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      final state = container.read(gameSessionProvider);
      expect(state.currentNotes, hasLength(1));
      expect(const ['E', 'G', 'A'], contains(state.currentNotes.first));
    });

    test('la nota unica tiene prioridad sobre la lista de foco', () async {
      container.read(practiceFocusNotesProvider.notifier).state =
          const ['E', 'G', 'A'];
      container.read(practiceFocusNoteProvider.notifier).state = 'B';
      final notifier = container.read(gameSessionProvider.notifier);
      await notifier.startRound();

      expect(container.read(gameSessionProvider).currentNotes, ['B']);
    });

    test('normalizePracticeFocusNotes limita a 4 notas validas (v2.1)', () {
      expect(
        normalizePracticeFocusNotes(['X', 'C', 'C', 'D', 'E', 'F', 'G']),
        ['C', 'D', 'E', 'F'],
      );
    });

    test('submitAnswer con respuesta parcial es incorrecta en chord', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setMode(GameMode.chord);
      await notifier.startRound();

      final notes = container.read(gameSessionProvider).currentNotes;
      // Solo una de 3 notas
      await notifier.submitAnswer([notes.first], 2.0);

      final state = container.read(gameSessionProvider);
      expect(state.lastResult!.isCorrect, false);
    });
  });
}

/// Notifier falso que inyecta un SRSSystem pre-configurado.
class _FakeSRSNotifier extends AsyncNotifier<SRSSystem>
    implements SRSNotifier {
  final SRSSystem _srs;
  _FakeSRSNotifier(this._srs);

  @override
  Future<SRSSystem> build() async => _srs;

  @override
  Future<void> saveProgress() async {
    await _srs.saveProgress();
  }

  @override
  Future<void> resetProgress() async {
    await _srs.resetProgress();
    ref.invalidateSelf();
  }
}

/// Random con nextDouble fijo para decidir rondas de foco.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}
