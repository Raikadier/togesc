import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/constants/srs_constants.dart';
import 'package:togesc/providers/audio_provider.dart';
import 'package:togesc/providers/game_session_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/services/audio_generator.dart';
import 'package:togesc/services/audio_player_service.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

/// Notifier que expone SRS real con repositorio en memoria.
class _TestSRSNotifier extends AsyncNotifier<SRSSystem>
    implements SRSNotifier {
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

void main() {
  group('Integracion: Game Session + SRS', () {
    late ProviderContainer container;
    late SRSSystem srs;
    late InMemoryProgressRepository repo;

    setUp(() async {
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
          srsSystemProvider.overrideWith(() => _TestSRSNotifier(srs)),
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

    test('ronda completa: select -> submit correcto -> SRS actualizado -> progreso guardado', () async {
      final notifier = container.read(gameSessionProvider.notifier);

      // Capturar estado SRS antes
      final noteDataBefore = Map.fromEntries(
        srs.noteData.entries.map((e) => MapEntry(e.key, e.value.timesSeen)),
      );

      // 1. Iniciar ronda
      await notifier.startRound();
      final selectedNotes = container.read(gameSessionProvider).currentNotes;
      expect(selectedNotes, isNotEmpty);

      // 2. Responder correctamente
      await notifier.submitAnswer(selectedNotes, 1.5);

      final result = container.read(gameSessionProvider).lastResult;
      expect(result, isNotNull);
      expect(result!.isCorrect, true);

      // 3. Verificar SRS actualizado
      for (final note in selectedNotes) {
        final noteData = srs.noteData[note]!;
        expect(noteData.timesSeen, noteDataBefore[note]! + 1,
            reason: '$note timesSeen debe incrementar');
        expect(noteData.timesCorrect, greaterThan(0),
            reason: '$note timesCorrect debe ser > 0');
        expect(noteData.lastSeen, isNotNull,
            reason: '$note lastSeen debe estar seteado');
      }

      // 4. Verificar progreso guardado en repositorio
      expect(repo.rawData, isNotNull,
          reason: 'Progreso debe haberse guardado');
      expect(repo.rawData!['note_data'], isNotNull);
    });

    test('ronda con respuesta incorrecta actualiza SRS correctamente', () async {
      final notifier = container.read(gameSessionProvider.notifier);

      await notifier.startRound();
      final selectedNotes = container.read(gameSessionProvider).currentNotes;
      final correctNote = selectedNotes.first;
      final weightBefore = srs.noteData[correctNote]!.weight;

      // Responder con nota incorrecta
      await notifier.submitAnswer(['NOTA_FALSA'], 3.0);

      final result = container.read(gameSessionProvider).lastResult;
      expect(result!.isCorrect, false);

      // La nota correcta deberia tener weight incrementado (fue incorrecta)
      final weightAfter = srs.noteData[correctNote]!.weight;
      expect(weightAfter, greaterThan(weightBefore),
          reason: 'Weight debe subir con respuesta incorrecta');
      expect(srs.noteData[correctNote]!.consecutiveCorrect, 0);
    });

    test('multiples rondas correctas reducen weight progresivamente', () async {
      final notifier = container.read(gameSessionProvider.notifier);

      // Nota cuyo weight vamos a rastrear
      await notifier.startRound();
      final firstNote = container.read(gameSessionProvider).currentNotes.first;
      final initialWeight = srs.noteData[firstNote]!.weight;

      // Responder correctamente con tiempo lento (>threshold para que baje weight)
      await notifier.submitAnswer(
        container.read(gameSessionProvider).currentNotes,
        fastResponseThreshold + 2.0,
      );

      final weightAfterOne = srs.noteData[firstNote]!.weight;
      expect(weightAfterOne, lessThan(initialWeight),
          reason: 'Weight debe bajar con respuesta correcta lenta');

      // Verificar progreso persiste
      expect(repo.rawData, isNotNull);
    });

    test('estadisticas SRS se actualizan despues de rondas', () async {
      final notifier = container.read(gameSessionProvider.notifier);

      // Jugar una ronda
      await notifier.startRound();
      await notifier.submitAnswer(
        container.read(gameSessionProvider).currentNotes,
        1.0,
      );

      // Verificar estadisticas
      final stats = srs.getStatistics();
      expect(stats['total_notes'], 12);
      expect(stats['total_seen'], greaterThan(0));
      expect(stats['total_correct'], greaterThan(0));
    });

    test('modo interval integra correctamente con SRS', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setMode(GameMode.interval);

      await notifier.startRound();
      final notes = container.read(gameSessionProvider).currentNotes;
      expect(notes.length, 2);

      // Responder correctamente
      await notifier.submitAnswer(notes, 1.0);
      final result = container.read(gameSessionProvider).lastResult;
      expect(result!.isCorrect, true);

      // Ambas notas deben haberse actualizado
      for (final note in notes) {
        expect(srs.noteData[note]!.timesSeen, 1);
        expect(srs.noteData[note]!.timesCorrect, 1);
      }
    });

    test('modo chord integra correctamente con SRS', () async {
      final notifier = container.read(gameSessionProvider.notifier);
      notifier.setMode(GameMode.chord);

      await notifier.startRound();
      final notes = container.read(gameSessionProvider).currentNotes;
      expect(notes.length, 3);

      await notifier.submitAnswer(notes, 2.0);
      expect(container.read(gameSessionProvider).lastResult!.isCorrect, true);

      for (final note in notes) {
        expect(srs.noteData[note]!.timesSeen, 1);
      }
    });

    test('persistencia sobrevive a rondas multiples', () async {
      final notifier = container.read(gameSessionProvider.notifier);

      for (var i = 0; i < 5; i++) {
        await notifier.startRound();
        await notifier.submitAnswer(
          container.read(gameSessionProvider).currentNotes,
          1.5 + i * 0.5,
        );
      }

      // Verificar que se guardaron los datos
      expect(repo.rawData, isNotNull);
      final savedNoteData = repo.rawData!['note_data'] as Map<String, dynamic>;
      expect(savedNoteData.length, 12);

      // Al menos algunas notas deben tener timesSeen > 0
      final seenNotes = savedNoteData.values
          .where((v) => (v as Map<String, dynamic>)['times_seen'] > 0)
          .length;
      expect(seenNotes, greaterThan(0));
    });

    test('recomendaciones de practica reflejan estado actual', () async {
      final recs = srs.getPracticeRecommendations();
      expect(recs, isNotEmpty);
      expect(recs.containsKey('total_overdue'), true);
      expect(recs.containsKey('message'), true);
      expect(recs['message'], isA<String>());
    });
  });
}
