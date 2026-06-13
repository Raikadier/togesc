import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/constants/srs_constants.dart';
import 'package:togesc/constants/notes.dart' as n;
import 'package:togesc/models/note_data.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/services/progress_repository.dart';

void main() {
  late SRSSystem srs;
  late DateTime fixedNow;

  setUp(() {
    fixedNow = DateTime(2026, 3, 15, 12, 0, 0);
    srs = SRSSystem(
      clock: () => fixedNow,
      random: Random(42), // Seed fijo para determinismo
    );
  });

  /// Helper para inicializar con datos por defecto.
  Future<void> initDefault() async {
    await srs.loadProgress();
  }

  group('Inicializacion', () {
    test('loadProgress sin repositorio inicializa 12 notas', () async {
      await initDefault();
      expect(srs.noteData.length, 12);
      for (final note in n.notes.keys) {
        expect(srs.noteData.containsKey(note), isTrue);
      }
    });

    test('todas las notas empiezan en fase de aprendizaje', () async {
      await initDefault();
      for (final data in srs.noteData.values) {
        expect(data.isLearning, isTrue);
        expect(data.weight, defaultNoteWeight);
      }
    });

    test('loadProgress con repositorio carga datos guardados', () async {
      final repo = InMemoryProgressRepository();
      await repo.save({
        'C': NoteData(weight: 5.0, consecutiveCorrect: 3),
        'D': NoteData(weight: 8.0),
      });

      final srsWithRepo = SRSSystem(repository: repo, clock: () => fixedNow);
      await srsWithRepo.loadProgress();

      expect(srsWithRepo.noteData['C']!.weight, 5.0);
      expect(srsWithRepo.noteData['C']!.consecutiveCorrect, 3);
      // Notas faltantes se inicializan con defaults
      expect(srsWithRepo.noteData['E']!.weight, defaultNoteWeight);
      expect(srsWithRepo.noteData.length, 12);
    });
  });

  group('getOverdueNotes', () {
    test('todas las notas sin nextReview son overdue', () async {
      await initDefault();
      final overdue = srs.getOverdueNotes();
      expect(overdue.length, 12);
    });

    test('notas con nextReview en el futuro no son overdue', () async {
      await initDefault();

      // Simular respuesta correcta para programar revisiones futuras
      srs.updateAfterResponse(
        notes: ['C'],
        correctNotes: ['C'],
        responseTime: 1.0,
      );

      // C ahora tiene nextReview en el futuro
      final overdue = srs.getOverdueNotes();
      expect(overdue.contains('C'), isFalse);
    });
  });

  group('getLearningNotes', () {
    test('todas las notas nuevas estan en aprendizaje', () async {
      await initDefault();
      final learning = srs.getLearningNotes();
      expect(learning.length, 12);
    });
  });

  group('selectNotes', () {
    test('selecciona el numero correcto de notas', () async {
      await initDefault();
      expect(srs.selectNotes(1).length, 1);
      expect(srs.selectNotes(3).length, 3);
      expect(srs.selectNotes(5).length, 5);
    });

    test('notas seleccionadas son unicas', () async {
      await initDefault();
      final selected = srs.selectNotes(5);
      expect(selected.toSet().length, 5);
    });

    test('respeta notePool', () async {
      await initDefault();
      final pool = ['C#', 'D#', 'F#', 'G#', 'A#'];
      final selected = srs.selectNotes(3, notePool: pool);
      for (final note in selected) {
        expect(pool.contains(note), isTrue);
      }
    });

    test('lanza error si numNotes > pool', () async {
      await initDefault();
      expect(
        () => srs.selectNotes(6, notePool: ['C#', 'D#', 'F#', 'G#', 'A#']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('updateAfterResponse - respuesta correcta', () {
    test('incrementa consecutiveCorrect', () async {
      await initDefault();
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      expect(srs.noteData['C']!.consecutiveCorrect, 1);
    });

    test('incrementa timesSeen y timesCorrect', () async {
      await initDefault();
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      expect(srs.noteData['C']!.timesSeen, 1);
      expect(srs.noteData['C']!.timesCorrect, 1);
    });

    test('weight se multiplica por decreaseFactor con respuesta rapida', () async {
      await initDefault();
      // Con responseTime=1.0 (< threshold=2.0), timeFactor=0, decreaseFactor=max(0.2, 1.0-0)=1.0
      // weight * 1.0 = weight (no cambia). Esto es correcto: respuesta rapida = factor 1.0.
      // Para que baje, responseTime debe ser > threshold: timeFactor > 0, decrease < 1.0
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      expect(srs.noteData['C']!.weight, defaultNoteWeight); // No cambia con respuesta rapida

      // Con responseTime=5.0 (> threshold), timeFactor=3.0, decrease=max(0.2, 1.0-0.3)=0.7
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 5.0);
      expect(srs.noteData['C']!.weight, closeTo(defaultNoteWeight * 0.7, 0.01));
    });

    test('establece lastSeen y nextReview', () async {
      await initDefault();
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      expect(srs.noteData['C']!.lastSeen, isNotNull);
      expect(srs.noteData['C']!.nextReview, isNotNull);
    });

    test('ease factor se clampea a maxEaseFactor (empieza en 2.5 = max)', () async {
      await initDefault();
      // Ya empieza en maxEaseFactor=2.5, no puede subir mas
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      expect(srs.noteData['C']!.easeFactor, maxEaseFactor);
    });

    test('ease factor sube tras bajar por error', () async {
      await initDefault();
      // Primero bajar con error
      srs.updateAfterResponse(notes: ['C'], correctNotes: [], responseTime: 5.0);
      final easeAfterError = srs.noteData['C']!.easeFactor;
      expect(easeAfterError, lessThan(maxEaseFactor));

      // Ahora respuesta rapida sube el ease
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      expect(srs.noteData['C']!.easeFactor, greaterThan(easeAfterError));
    });

    test('ease factor no sube con respuesta lenta (>= 2s)', () async {
      await initDefault();
      // Primero bajar con error
      srs.updateAfterResponse(notes: ['C'], correctNotes: [], responseTime: 5.0);
      final easeAfterError = srs.noteData['C']!.easeFactor;

      // Respuesta lenta correcta no sube ease
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 5.0);
      expect(srs.noteData['C']!.easeFactor, easeAfterError);
    });
  });

  group('updateAfterResponse - respuesta incorrecta', () {
    test('resetea consecutiveCorrect a 0', () async {
      await initDefault();
      // Primero acertar 3 veces
      for (var i = 0; i < 3; i++) {
        srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      }
      expect(srs.noteData['C']!.consecutiveCorrect, 3);

      // Ahora fallar
      srs.updateAfterResponse(notes: ['C'], correctNotes: [], responseTime: 5.0);
      expect(srs.noteData['C']!.consecutiveCorrect, 0);
    });

    test('aumenta weight', () async {
      await initDefault();
      final weightBefore = srs.noteData['C']!.weight;
      srs.updateAfterResponse(notes: ['C'], correctNotes: [], responseTime: 5.0);
      expect(srs.noteData['C']!.weight, greaterThan(weightBefore));
    });

    test('disminuye ease factor', () async {
      await initDefault();
      final easeBefore = srs.noteData['C']!.easeFactor;
      srs.updateAfterResponse(notes: ['C'], correctNotes: [], responseTime: 5.0);
      expect(srs.noteData['C']!.easeFactor, lessThan(easeBefore));
    });

    test('ease factor no baja de minEaseFactor', () async {
      await initDefault();
      // Fallar muchas veces
      for (var i = 0; i < 20; i++) {
        srs.updateAfterResponse(notes: ['C'], correctNotes: [], responseTime: 5.0);
      }
      expect(srs.noteData['C']!.easeFactor, greaterThanOrEqualTo(minEaseFactor));
    });
  });

  group('Graduacion', () {
    test('5 aciertos consecutivos graduan la nota', () async {
      await initDefault();
      for (var i = 0; i < learningPhaseThreshold; i++) {
        srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      }
      expect(srs.noteData['C']!.isLearning, isFalse);
      expect(srs.noteData['C']!.intervalIndex, greaterThanOrEqualTo(0));
    });

    test('4 aciertos no graduan', () async {
      await initDefault();
      for (var i = 0; i < learningPhaseThreshold - 1; i++) {
        srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      }
      expect(srs.noteData['C']!.isLearning, isTrue);
    });
  });

  group('Regresion de consolidacion a aprendizaje', () {
    test('error en consolidacion con interval bajo vuelve a learning', () async {
      await initDefault();
      // Graduar la nota
      for (var i = 0; i < learningPhaseThreshold; i++) {
        srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      }
      expect(srs.noteData['C']!.isLearning, isFalse);

      // Fallar - intervalIndex es 1 despues de graduacion, - forgetPenaltySteps = -1 -> 0 -> isLearning
      srs.updateAfterResponse(notes: ['C'], correctNotes: [], responseTime: 5.0);
      // intervalIndex deberia ser 0 (max(0, 1-2) = 0), que es < 2, entonces isLearning = true
      expect(srs.noteData['C']!.isLearning, isTrue);
    });
  });

  group('Penalizacion de notas incorrectas externas', () {
    test('penaliza notas incorrectas que no estaban en el ejercicio', () async {
      await initDefault();
      final weightBefore = srs.noteData['D']!.weight;
      srs.updateAfterResponse(
        notes: ['C'],
        correctNotes: ['C'],
        wrongNotes: {'D'},
        responseTime: 1.0,
      );
      expect(srs.noteData['D']!.weight, greaterThan(weightBefore));
    });

    test('no penaliza notas incorrectas que estaban en el ejercicio', () async {
      await initDefault();
      final weightBefore = srs.noteData['C']!.weight;
      // C esta en notes y en wrongNotes, pero fue correcta
      srs.updateAfterResponse(
        notes: ['C'],
        correctNotes: ['C'],
        wrongNotes: {'C'},
        responseTime: 1.0,
      );
      // Con respuesta rapida (1.0s < 2.0s threshold), decreaseFactor=1.0, weight no cambia
      // Lo importante es que no SUBE por estar en wrongNotes (porque esta en notes)
      expect(srs.noteData['C']!.weight, weightBefore);
    });
  });

  group('_scheduleNextReview', () {
    test('primer acierto en learning programa en intervalLearning2 dias', () async {
      await initDefault();
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      final nextReview = DateTime.parse(srs.noteData['C']!.nextReview!);
      final expected = fixedNow.add(Duration(days: intervalLearning2));
      expect(nextReview, expected);
    });

    test('error en learning programa en intervalLearning1 dia', () async {
      await initDefault();
      srs.updateAfterResponse(notes: ['C'], correctNotes: [], responseTime: 5.0);
      final nextReview = DateTime.parse(srs.noteData['C']!.nextReview!);
      final expected = fixedNow.add(Duration(days: intervalLearning1));
      expect(nextReview, expected);
    });
  });

  group('getStatistics', () {
    test('estadisticas con datos por defecto', () async {
      await initDefault();
      final stats = srs.getStatistics();
      expect(stats['total_notes'], 12);
      expect(stats['learning_phase'], 12);
      expect(stats['graduated'], 0);
      expect(stats['total_seen'], 0);
      expect(stats['accuracy_percentage'], 0.0);
    });

    test('estadisticas despues de respuestas', () async {
      await initDefault();
      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      srs.updateAfterResponse(notes: ['D'], correctNotes: [], responseTime: 5.0);

      final stats = srs.getStatistics();
      expect(stats['total_seen'], 2);
      expect(stats['total_correct'], 1);
      expect(stats['accuracy_percentage'], 50.0);
    });
  });

  group('getPracticeRecommendations', () {
    test('recomienda notas con datos por defecto', () async {
      await initDefault();
      final recs = srs.getPracticeRecommendations();
      expect(recs['total_overdue'], 12);
      expect(recs['message'], isNotEmpty);
    });
  });

  group('Persistencia', () {
    test('save y load preservan estado', () async {
      final repo = InMemoryProgressRepository();
      final srs1 = SRSSystem(repository: repo, clock: () => fixedNow);
      await srs1.loadProgress();

      srs1.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      await srs1.saveProgress();

      final srs2 = SRSSystem(repository: repo, clock: () => fixedNow);
      await srs2.loadProgress();

      expect(srs2.noteData['C']!.consecutiveCorrect, 1);
      expect(srs2.noteData['C']!.timesCorrect, 1);
    });
  });

  group('resetProgress', () {
    test('reinicia todos los datos', () async {
      final repo = InMemoryProgressRepository();
      final srsR = SRSSystem(repository: repo, clock: () => fixedNow);
      await srsR.loadProgress();

      srsR.updateAfterResponse(notes: ['C'], correctNotes: ['C'], responseTime: 1.0);
      await srsR.resetProgress();

      expect(srsR.noteData['C']!.consecutiveCorrect, 0);
      expect(srsR.noteData['C']!.weight, defaultNoteWeight);
    });
  });
}
