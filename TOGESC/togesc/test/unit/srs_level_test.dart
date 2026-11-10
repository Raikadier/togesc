import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/models/note_data.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/utils/srs_level.dart';

void main() {
  group('srsLevelFromValues', () {
    test('aprendizaje escala 0..2 con umbral 5', () {
      int level(int cc) => srsLevelFromValues(
            isLearning: true,
            consecutiveCorrect: cc,
            intervalIndex: 0,
            learningThreshold: 5,
          );
      expect(level(0), 0);
      expect(level(1), 0);
      expect(level(2), 1);
      expect(level(3), 1);
      expect(level(4), 2);
      // Nunca supera 2 mientras siga en aprendizaje.
      expect(level(9), 2);
    });

    test('consolidada escala 3..5 segun intervalIndex', () {
      int level(int interval) => srsLevelFromValues(
            isLearning: false,
            consecutiveCorrect: 0,
            intervalIndex: interval,
          );
      expect(level(0), 3);
      expect(level(1), 3);
      expect(level(2), 4);
      expect(level(3), 5);
      expect(level(6), 5);
    });

    test('umbral invalido y contadores negativos no rompen', () {
      expect(
        srsLevelFromValues(
          isLearning: true,
          consecutiveCorrect: -3,
          intervalIndex: 0,
          learningThreshold: 0,
        ),
        0,
      );
      expect(
        srsLevelFromValues(
          isLearning: true,
          consecutiveCorrect: 1,
          intervalIndex: 0,
          learningThreshold: 0,
        ),
        2,
      );
    });

    test('perfil intenso (umbral 4) sube antes', () {
      expect(
        srsLevelFromValues(
          isLearning: true,
          consecutiveCorrect: 3,
          intervalIndex: 0,
          learningThreshold: 4,
        ),
        2,
      );
    });
  });

  group('srsLevel', () {
    test('NoteData nueva es nivel 0', () {
      expect(srsLevel(NoteData()), 0);
    });

    test('NoteData consolidada', () {
      expect(srsLevel(NoteData(isLearning: false, intervalIndex: 2)), 4);
    });

    test('summary usa intervalIndex', () {
      const summary = NoteProgressSummary(
        note: 'C',
        isLearning: false,
        consecutiveCorrect: 7,
        timesSeen: 10,
        timesCorrect: 9,
        weight: 1,
        isOverdue: false,
        intervalIndex: 3,
      );
      expect(srsLevelForSummary(summary), 5);
    });

    test('graduarse en el SRS real da nivel 3 y sigue subiendo', () async {
      final srs = SRSSystem(clock: () => DateTime(2026, 1, 1));
      await srs.loadProgress();
      for (var i = 0; i < 5; i++) {
        srs.updateAfterResponse(notes: ['C'], correctNotes: ['C']);
      }
      final graduated = srs.noteData['C']!;
      expect(graduated.isLearning, isFalse);
      expect(srsLevel(graduated), 3);

      srs.updateAfterResponse(notes: ['C'], correctNotes: ['C']);
      expect(srsLevel(srs.noteData['C']!), 4);
    });
  });

  group('srsLevelChangeFromSrsChange', () {
    test('lee old/new de updateAfterResponse', () async {
      final srs = SRSSystem(clock: () => DateTime(2026, 1, 1));
      await srs.loadProgress();
      for (var i = 0; i < 3; i++) {
        srs.updateAfterResponse(notes: ['D'], correctNotes: ['D']);
      }
      final changes =
          srs.updateAfterResponse(notes: ['D'], correctNotes: ['D']);
      final change = srsLevelChangeFromSrsChange(changes['D']);
      expect(change, isNotNull);
      expect(change!.before, 1); // 3 aciertos
      expect(change.after, 2); // 4 aciertos
      expect(change.improved, isTrue);
    });

    test('un fallo baja el nivel', () async {
      final srs = SRSSystem(clock: () => DateTime(2026, 1, 1));
      await srs.loadProgress();
      for (var i = 0; i < 4; i++) {
        srs.updateAfterResponse(notes: ['E'], correctNotes: ['E']);
      }
      final changes = srs.updateAfterResponse(notes: ['E'], correctNotes: []);
      final change = srsLevelChangeFromSrsChange(changes['E'])!;
      expect(change.before, 2);
      expect(change.after, 0);
      expect(change.dropped, isTrue);
    });

    test('nota nueva: fallo 0→0, primer acierto 0→0, segundo 0→1', () async {
      final srs = SRSSystem(clock: () => DateTime(2026, 1, 1));
      await srs.loadProgress();
      SrsLevelChange round({required bool hit}) => srsLevelChangeFromSrsChange(
            srs.updateAfterResponse(
              notes: ['C'],
              correctNotes: hit ? ['C'] : [],
            )['C'],
          )!;
      final miss = round(hit: false);
      expect((miss.before, miss.after), (0, 0));
      // floor(3·1/5) = 0: el primer acierto no sube un punto (umbral 5).
      final first = round(hit: true);
      expect((first.before, first.after), (0, 0));
      final second = round(hit: true);
      expect((second.before, second.after), (0, 1));
      expect(second.improved, isTrue);
    });

    test('mapas invalidos devuelven null', () {
      expect(srsLevelChangeFromSrsChange(null), isNull);
      expect(srsLevelChangeFromSrsChange({'old': 1, 'new': 2}), isNull);
      expect(srsLevelFromSnapshot({'is_learning': 'x'}), isNull);
    });
  });
}
