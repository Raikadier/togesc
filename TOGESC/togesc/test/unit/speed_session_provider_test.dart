import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/speed_session_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

/// Notifier falso para SRS.
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
  late SRSSystem srs;

  setUp(() async {
    final repo = InMemoryProgressRepository();
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
      ],
    );

    await container.read(srsSystemProvider.future);
  });

  tearDown(() {
    container.dispose();
  });

  group('SpeedSessionState', () {
    test('estado inicial correcto', () {
      final state = container.read(speedSessionProvider);
      expect(state.state, SpeedState.idle);
      expect(state.targetMode, GameMode.singleNote);
      expect(state.currentTimeLimit, speedInitialTime);
      expect(state.remainingTime, speedInitialTime);
      expect(state.currentNotes, isEmpty);
      expect(state.consecutiveCorrect, 0);
      expect(state.responseTimes, isEmpty);
      expect(state.useRandomInstrument, true);
    });

    test('averageTime es 0 cuando no hay tiempos', () {
      final state = container.read(speedSessionProvider);
      expect(state.averageTime, 0.0);
    });

    test('bestTime es 0 cuando no hay tiempos', () {
      final state = container.read(speedSessionProvider);
      expect(state.bestTime, 0.0);
    });

    test('averageTime calcula correctamente', () {
      const state = SpeedSessionState(responseTimes: [2.0, 4.0, 6.0]);
      expect(state.averageTime, 4.0);
    });

    test('bestTime retorna el menor', () {
      const state = SpeedSessionState(responseTimes: [2.0, 4.0, 1.5]);
      expect(state.bestTime, 1.5);
    });
  });

  group('SpeedSessionNotifier', () {
    test('setTargetMode cambia el modo', () {
      final notifier = container.read(speedSessionProvider.notifier);
      notifier.setTargetMode(GameMode.chord);

      expect(container.read(speedSessionProvider).targetMode, GameMode.chord);
    });

    test('startRound selecciona notas y transiciona a waitingForAnswer', () async {
      final notifier = container.read(speedSessionProvider.notifier);
      await notifier.startRound();

      final state = container.read(speedSessionProvider);
      expect(state.state, SpeedState.waitingForAnswer);
      expect(state.currentNotes, isNotEmpty);
      expect(state.currentNotes.length, 1); // singleNote
    });

    test('startRound en modo interval selecciona 2 notas', () async {
      final notifier = container.read(speedSessionProvider.notifier);
      notifier.setTargetMode(GameMode.interval);
      await notifier.startRound();

      expect(container.read(speedSessionProvider).currentNotes.length, 2);
    });

    test('startRound en modo chord selecciona 3 notas', () async {
      final notifier = container.read(speedSessionProvider.notifier);
      notifier.setTargetMode(GameMode.chord);
      await notifier.startRound();

      expect(container.read(speedSessionProvider).currentNotes.length, 3);
    });

    test('submitAnswer correcta incrementa consecutiveCorrect y reduce timeLimit', () async {
      final notifier = container.read(speedSessionProvider.notifier);
      await notifier.startRound();

      final notes = container.read(speedSessionProvider).currentNotes;
      notifier.submitAnswer(notes, 2.0);

      final state = container.read(speedSessionProvider);
      expect(state.state, SpeedState.correct);
      expect(state.consecutiveCorrect, 1);
      expect(state.currentTimeLimit, speedInitialTime - speedCorrectDecrease);
      expect(state.responseTimes, [2.0]);
    });

    test('submitAnswer incorrecta no cambia consecutiveCorrect ni timeLimit', () async {
      final notifier = container.read(speedSessionProvider.notifier);
      await notifier.startRound();

      notifier.submitAnswer(['X'], 3.0);

      final state = container.read(speedSessionProvider);
      expect(state.state, SpeedState.incorrect);
      expect(state.consecutiveCorrect, 0);
      expect(state.currentTimeLimit, speedInitialTime); // sin cambio
      expect(state.responseTimes, [3.0]);
    });

    test('multiples respuestas correctas reducen timeLimit progresivamente', () async {
      final notifier = container.read(speedSessionProvider.notifier);

      // Ronda 1
      await notifier.startRound();
      var notes = container.read(speedSessionProvider).currentNotes;
      notifier.submitAnswer(notes, 1.0);
      expect(container.read(speedSessionProvider).currentTimeLimit,
          speedInitialTime - speedCorrectDecrease);

      // Ronda 2
      await notifier.startRound();
      notes = container.read(speedSessionProvider).currentNotes;
      notifier.submitAnswer(notes, 1.0);
      expect(container.read(speedSessionProvider).currentTimeLimit,
          speedInitialTime - 2 * speedCorrectDecrease);
      expect(container.read(speedSessionProvider).consecutiveCorrect, 2);
    });

    test('timeLimit no baja por debajo de speedMinTime', () async {
      final notifier = container.read(speedSessionProvider.notifier);

      // Simular muchas respuestas correctas
      for (var i = 0; i < 20; i++) {
        await notifier.startRound();
        final notes = container.read(speedSessionProvider).currentNotes;
        notifier.submitAnswer(notes, 0.5);
      }

      expect(container.read(speedSessionProvider).currentTimeLimit,
          greaterThanOrEqualTo(speedMinTime));
    });

    test('retry reinicia el estado', () async {
      final notifier = container.read(speedSessionProvider.notifier);

      await notifier.startRound();
      final notes = container.read(speedSessionProvider).currentNotes;
      notifier.submitAnswer(notes, 1.0);

      notifier.retry();

      final state = container.read(speedSessionProvider);
      expect(state.state, SpeedState.idle);
      expect(state.currentTimeLimit, speedInitialTime);
      expect(state.remainingTime, speedInitialTime);
      expect(state.consecutiveCorrect, 0);
      expect(state.responseTimes, isEmpty);
    });

    test('reset vuelve al estado completamente inicial', () async {
      final notifier = container.read(speedSessionProvider.notifier);
      notifier.setTargetMode(GameMode.chord);
      await notifier.startRound();
      final notes = container.read(speedSessionProvider).currentNotes;
      notifier.submitAnswer(notes, 1.0);

      notifier.reset();

      final state = container.read(speedSessionProvider);
      expect(state.state, SpeedState.idle);
      expect(state.targetMode, GameMode.singleNote);
      expect(state.currentTimeLimit, speedInitialTime);
      expect(state.consecutiveCorrect, 0);
      expect(state.responseTimes, isEmpty);
    });

    test('responseTimes acumula tiempos de respuesta', () async {
      final notifier = container.read(speedSessionProvider.notifier);

      await notifier.startRound();
      var notes = container.read(speedSessionProvider).currentNotes;
      notifier.submitAnswer(notes, 2.5);

      await notifier.startRound();
      notes = container.read(speedSessionProvider).currentNotes;
      notifier.submitAnswer(notes, 1.8);

      final state = container.read(speedSessionProvider);
      expect(state.responseTimes, [2.5, 1.8]);
      expect(state.averageTime, closeTo(2.15, 0.01));
      expect(state.bestTime, 1.8);
    });

    test('submitAnswer parcial en chord es incorrecta', () async {
      final notifier = container.read(speedSessionProvider.notifier);
      notifier.setTargetMode(GameMode.chord);
      await notifier.startRound();

      final notes = container.read(speedSessionProvider).currentNotes;
      notifier.submitAnswer([notes.first], 2.0);

      expect(container.read(speedSessionProvider).state, SpeedState.incorrect);
    });
  });
}
