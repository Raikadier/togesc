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
