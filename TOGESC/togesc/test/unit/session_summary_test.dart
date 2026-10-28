import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/models/practice_session_log.dart' show chromaticNotes;
import 'package:togesc/utils/session_summary.dart';

NoteProgressSummary _s(
  String note, {
  int seen = 0,
  int correct = 0,
  bool learning = true,
  int cc = 0,
  int interval = 0,
}) =>
    NoteProgressSummary(
      note: note,
      isLearning: learning,
      consecutiveCorrect: cc,
      timesSeen: seen,
      timesCorrect: correct,
      weight: 1,
      isOverdue: false,
      intervalIndex: interval,
    );

void main() {
  group('snapshotSrs', () {
    test('guarda nivel, precisión y vistas por nota', () {
      final snap = snapshotSrs([
        _s('C', seen: 10, correct: 7, cc: 2),
        _s('D'),
      ]);
      expect(snap['C']!.level, 1);
      expect(snap['C']!.accuracyPercent, 70);
      expect(snap['C']!.timesSeen, 10);
      expect(snap['D']!.level, 0);
      expect(snap['D']!.accuracyPercent, isNull);
    });
  });

  group('buildSessionLevelChanges (antes/después)', () {
    final before = snapshotSrs([
      _s('C', seen: 4, correct: 2, cc: 0),
      _s('D', seen: 4, correct: 4, cc: 4),
      _s('E', seen: 10, correct: 9, learning: false, interval: 2),
      _s('F'),
    ]);

    test('una fila por nota de la sesión, ordenadas por subida', () {
      final after = [
        // C: 0 → 1 (2 seguidas).
        _s('C', seen: 6, correct: 4, cc: 2),
        // D: 2 → 3 (se gradúa).
        _s('D', seen: 5, correct: 5, learning: false, interval: 1),
        // E: 4 → 3 (falla y baja un paso).
        _s('E', seen: 11, correct: 9, learning: false, interval: 1),
        // F: no salió en la sesión.
        _s('F', seen: 1, correct: 1, cc: 1),
      ];
      final changes = buildSessionLevelChanges(
        before: before,
        after: after,
        sessionNotes: ['E', 'C', 'D', 'C'],
        chromaticOrder: chromaticNotes,
      );
      expect(changes.map((c) => c.note), ['C', 'D', 'E']);
      expect(changes[0].before, 0);
      expect(changes[0].after, 1);
      expect(changes[0].improved, isTrue);
      expect(changes[1].before, 2);
      expect(changes[1].after, 3);
      expect(changes[2].before, 4);
      expect(changes[2].after, 3);
      expect(changes[2].dropped, isTrue);
      expect(changes[0].accuracyBefore, 50);
      expect(changes[0].accuracyAfter, closeTo(66.7, 0.1));
    });

    test('sin cambio de nivel queda como «igual»', () {
      final changes = buildSessionLevelChanges(
        before: before,
        after: [_s('C', seen: 5, correct: 2, cc: 1)],
        sessionNotes: ['C'],
      );
      expect(changes.single.delta, 0);
      expect(changes.single.improved, isFalse);
      expect(changes.single.dropped, isFalse);
    });

    test('notas sin instantánea o sin resumen se omiten', () {
      final changes = buildSessionLevelChanges(
        before: const {},
        after: [_s('C', seen: 1, correct: 1, cc: 1)],
        sessionNotes: ['C'],
      );
      expect(changes, isEmpty);
    });
  });

  group('averageResponseTimeSec', () {
    test('media de los tiempos medidos', () {
      expect(averageResponseTimeSec([1.0, 2.0, 3.0]), 2.0);
    });

    test('ignora tiempos no medidos y sin datos da null', () {
      expect(averageResponseTimeSec([0, 2.0, -1, 4.0]), 3.0);
      expect(averageResponseTimeSec(const []), isNull);
      expect(averageResponseTimeSec(const [0.0]), isNull);
    });

    test('formatSecondsEs con coma decimal', () {
      expect(formatSecondsEs(2.44), '2,4 s');
      expect(formatSecondsEs(1), '1,0 s');
    });
  });

  group('SessionMedal y frase', () {
    test('umbrales 75 / 50', () {
      expect(SessionMedal.forAccuracy(100), SessionMedal.great);
      expect(SessionMedal.forAccuracy(75), SessionMedal.great);
      expect(SessionMedal.forAccuracy(74.9), SessionMedal.good);
      expect(SessionMedal.forAccuracy(50), SessionMedal.good);
      expect(SessionMedal.forAccuracy(49.9), SessionMedal.keepGoing);
      expect(SessionMedal.great.headline, 'Gran oído hoy');
      expect(SessionMedal.good.headline, 'Vas por buen camino');
      expect(SessionMedal.keepGoing.headline, 'Cada fallo afina el repaso');
    });

    test('frase según cuántas notas subieron', () {
      const up = SessionLevelChange(
        note: 'C',
        before: 0,
        after: 1,
        accuracyBefore: null,
        accuracyAfter: 100,
      );
      const same = SessionLevelChange(
        note: 'D',
        before: 1,
        after: 1,
        accuracyBefore: 50,
        accuracyAfter: 50,
      );
      expect(
        sessionSummaryLead(const [same]),
        'El SRS repetirá antes las notas que fallaste.',
      );
      expect(sessionSummaryLead(const [up, same]), '1 nota subió de nivel SRS.');
      expect(
        sessionSummaryLead(const [up, up]),
        '2 notas subieron de nivel SRS.',
      );
    });
  });
}
