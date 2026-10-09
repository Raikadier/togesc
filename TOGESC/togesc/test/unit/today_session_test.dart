import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/constants/notes.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/utils/today_session.dart';

NoteProgressSummary _summary(
  String note, {
  int seen = 0,
  int correct = 0,
  bool learning = true,
  bool overdue = false,
}) {
  return NoteProgressSummary(
    note: note,
    isLearning: learning,
    consecutiveCorrect: 0,
    timesSeen: seen,
    timesCorrect: correct,
    weight: 10,
    isOverdue: overdue,
  );
}

List<NoteProgressSummary> _allUnseen() =>
    [for (final note in notes.keys) _summary(note, overdue: true)];

void main() {
  group('selectTodayFocusNotes', () {
    test('sin datos: tres naturales en orden C, D, E', () {
      final focus = selectTodayFocusNotes(summaries: _allUnseen());
      expect(focus.map((f) => f.note), ['C', 'D', 'E']);
      expect(focus.every((f) => f.accuracyPercent == null), isTrue);
    });

    test('lista vacia mientras el SRS carga', () {
      expect(selectTodayFocusNotes(summaries: const []), isEmpty);
    });

    test('criticas primero, por dias de retraso', () {
      final summaries = _allUnseen();
      final focus = selectTodayFocusNotes(
        summaries: summaries,
        criticalNotes: const [('G', 3), ('A#', 9)],
      );
      expect(focus.map((f) => f.note), ['A#', 'G', 'C']);
      expect(focus[0].isCritical, isTrue);
      expect(focus[2].isCritical, isFalse);
    });

    test('despues atrasadas y en aprendizaje de menor precision', () {
      NoteProgressSummary build(String note) {
        switch (note) {
          case 'D':
            return _summary('D', seen: 10, correct: 9, overdue: true);
          case 'E':
            return _summary('E', seen: 10, correct: 3, overdue: true);
          case 'F':
            return _summary('F', seen: 10, correct: 2, learning: true);
          case 'B':
            return _summary('B', seen: 10, correct: 1, learning: false);
          default:
            return _summary(note);
        }
      }

      final summaries = [for (final note in notes.keys) build(note)];
      final focus = selectTodayFocusNotes(summaries: summaries);
      // Atrasadas vistas (E 30 %, D 90 %) y luego aprendizaje vista (F 20 %).
      expect(focus.map((f) => f.note), ['E', 'D', 'F']);
      expect(focus.first.accuracyPercent, closeTo(30, 0.001));
    });

    test('respeta el pool configurado', () {
      final focus = selectTodayFocusNotes(
        summaries: _allUnseen(),
        criticalNotes: const [('C', 5)],
        allowedNotes: const ['F#', 'G', 'A'],
      );
      expect(focus.map((f) => f.note), ['G', 'A', 'F#']);
    });

    test('count limita el resultado', () {
      final focus = selectTodayFocusNotes(summaries: _allUnseen(), count: 1);
      expect(focus, hasLength(1));
      expect(selectTodayFocusNotes(summaries: _allUnseen(), count: 0), isEmpty);
    });

    test('criticalNotesFromRecommendations ignora formatos invalidos', () {
      expect(criticalNotesFromRecommendations(const {}), isEmpty);
      expect(
        criticalNotesFromRecommendations({
          'critical_notes': [('C', 4), 'x', 3],
        }),
        [('C', 4)],
      );
    });
  });

  group('buildResumeSessionInfo', () {
    final enteredAt = DateTime(2026, 10, 9, 16);

    test('sin datos devuelve null', () {
      expect(buildResumeSessionInfo(last: null, history: const []), isNull);
    });

    test('toma rondas de la sesion registrada al salir', () {
      final last = LastPracticeSession(
        modeId: GameMode.singleNote.id,
        kind: PracticeKind.game,
        practicedAt: enteredAt,
      );
      final history = [
        PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 8,
          correctRounds: 6,
          endedAt: DateTime(2026, 10, 9, 16, 10),
        ),
        PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 20,
          correctRounds: 10,
          endedAt: DateTime(2026, 10, 1),
        ),
      ];
      final info = buildResumeSessionInfo(last: last, history: history)!;
      expect(info.label, 'Una sola nota');
      expect(info.route, '/game/1');
      expect(info.rounds, 8);
      expect(info.correctRounds, 6);
      expect(info.at, DateTime(2026, 10, 9, 16, 10));
    });

    test('no mezcla rondas de otro modo ni de una sesion antigua', () {
      final last = LastPracticeSession(
        modeId: GameMode.interval.id,
        kind: PracticeKind.game,
        practicedAt: enteredAt,
      );
      final history = [
        PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 8,
          correctRounds: 6,
          endedAt: DateTime(2026, 10, 9, 17),
        ),
        PracticeSessionLog(
          modeId: GameMode.interval.id,
          kind: PracticeKind.game,
          roundsCompleted: 5,
          correctRounds: 5,
          endedAt: DateTime(2026, 10, 2),
        ),
      ];
      final info = buildResumeSessionInfo(last: last, history: history)!;
      expect(info.modeId, GameMode.interval.id);
      expect(info.rounds, isNull);
      expect(info.at, enteredAt);
    });

    test('velocidad conserva su tipo y su ruta', () {
      final last = LastPracticeSession(
        modeId: GameMode.chord.id,
        kind: PracticeKind.speed,
        practicedAt: enteredAt,
      );
      final history = [
        PracticeSessionLog(
          modeId: GameMode.chord.id,
          kind: PracticeKind.game,
          roundsCompleted: 9,
          correctRounds: 9,
          endedAt: DateTime(2026, 10, 9, 18),
        ),
      ];
      final info = buildResumeSessionInfo(last: last, history: history)!;
      expect(info.kind, PracticeKind.speed);
      expect(info.route, '/speed/game/3');
      expect(info.rounds, isNull);
    });

    test('sin ultima sesion usa la entrada mas reciente del historial', () {
      final history = [
        PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 4,
          correctRounds: 2,
          endedAt: DateTime(2026, 10, 1),
        ),
        PracticeSessionLog(
          modeId: GameMode.chord.id,
          kind: PracticeKind.game,
          roundsCompleted: 12,
          correctRounds: 10,
          endedAt: DateTime(2026, 10, 8),
        ),
      ];
      final info = buildResumeSessionInfo(last: null, history: history)!;
      expect(info.modeId, GameMode.chord.id);
      expect(info.rounds, 12);
      expect(info.session.route, '/game/3');
    });
  });
}
