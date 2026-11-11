import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/utils/milestones.dart';
import 'package:togesc/utils/session_summary.dart';

NoteProgressSummary _note(String note, {int seen = 10, int correct = 9}) =>
    NoteProgressSummary(
      note: note,
      isLearning: false,
      consecutiveCorrect: 0,
      timesSeen: seen,
      timesCorrect: correct,
      weight: 1,
      isOverdue: false,
    );

/// Todas las notas con [seen]/[correct], salvo las de [overrides].
List<NoteProgressSummary> _all({
  int seen = 0,
  int correct = 0,
  Map<String, NoteProgressSummary> overrides = const {},
}) => [
  for (final n in chromaticNotes)
    overrides[n] ?? _note(n, seen: seen, correct: correct),
];

Map<String, NoteSrsSnapshot> _snap(List<NoteProgressSummary> s) =>
    snapshotSrs(s);

PracticeSessionLog _log(DateTime at, {int mode = 1, int correct = 5}) =>
    PracticeSessionLog(
      modeId: mode,
      kind: PracticeKind.game,
      roundsCompleted: 10,
      correctRounds: correct,
      endedAt: at,
    );

void main() {
  final now = DateTime(2026, 11, 11, 18);

  List<Milestone> run({
    required List<NoteProgressSummary> before,
    required List<NoteProgressSummary> after,
    int rounds = 10,
    int correct = 5,
    int prevSessions = 0,
    double? prevBest,
  }) => sessionMilestones(
    before: _snap(before),
    after: after,
    roundsCompleted: rounds,
    correctRounds: correct,
    previousSessionsSameMode: prevSessions,
    previousBestAccuracy: prevBest,
    now: now,
  );

  group('sessionMilestones', () {
    test('sin hitos: nada cambia y no hay récord', () {
      final notes = _all(seen: 3, correct: 1);
      expect(
        run(before: notes, after: notes, prevSessions: 5, prevBest: 80),
        isEmpty,
      );
    });

    test('nota consolidada: solo la que cruza en esta sesión', () {
      final before = _all(
        overrides: {
          'C': _note('C', seen: 10, correct: 7), // 70 %: en curso
          'D': _note('D', seen: 10, correct: 9), // ya consolidada
        },
      );
      final after = _all(
        overrides: {
          'C': _note('C', seen: 12, correct: 10), // 83 %: consolidada
          'D': _note('D', seen: 11, correct: 10),
        },
      );
      final got = run(before: before, after: after);
      expect(got, hasLength(1));
      expect(got.single.kind, MilestoneKind.noteConsolidated);
      expect(got.single.note, 'C');
      expect(milestoneLabel(got.single), 'C, consolidada');
    });

    test('con 4 intentos no se consolida aunque acierte todo', () {
      final after = _all(overrides: {'C': _note('C', seen: 4, correct: 4)});
      expect(run(before: _all(), after: after), isEmpty);
    });

    test('sin estado inicial no se declara ninguna nota nueva', () {
      final got = sessionMilestones(
        before: const {},
        after: _all(seen: 10, correct: 10),
        roundsCompleted: 10,
        correctRounds: 10,
        previousSessionsSameMode: 0,
        previousBestAccuracy: null,
        now: now,
      );
      expect(got, isEmpty);
    });

    test('octava completa: al consolidarse la duodécima', () {
      final before = _all(
        seen: 10,
        correct: 9,
        overrides: {'B': _note('B', seen: 10, correct: 6)},
      );
      final after = _all(seen: 10, correct: 9);
      final kinds = run(before: before, after: after).map((m) => m.kind);
      expect(kinds, [
        MilestoneKind.noteConsolidated,
        MilestoneKind.octaveComplete,
      ]);
      // Si ya estaba completa, no se repite.
      expect(run(before: after, after: after), isEmpty);
    });

    test('mejor sesión: necesita 3 sesiones previas y superar la mejor', () {
      final notes = _all();
      List<MilestoneKind> best(int prev, double? bestAcc, int correct) => run(
        before: notes,
        after: notes,
        correct: correct,
        prevSessions: prev,
        prevBest: bestAcc,
      ).map((m) => m.kind).toList();

      expect(best(3, 80, 9), [MilestoneKind.bestSession]);
      expect(best(2, 80, 9), isEmpty);
      expect(best(3, 90, 9), isEmpty, reason: 'igualar no es récord');
      expect(best(3, null, 9), isEmpty);
      final m = run(
        before: notes,
        after: notes,
        correct: 9,
        prevSessions: 3,
        prevBest: 80,
      ).single;
      expect(milestoneLabel(m, inSummary: true), 'Tu mejor sesión hasta hoy');
      expect(milestoneLabel(m), 'Mejor sesión: 90 %');
    });
  });

  group('racha récord', () {
    test('desde 2 días y por encima de la mejor anterior', () {
      expect(
        streakRecordMilestone(streakDays: 1, previousBest: 0, now: now),
        isNull,
      );
      expect(
        streakRecordMilestone(streakDays: 4, previousBest: 4, now: now),
        isNull,
      );
      final m = streakRecordMilestone(
        streakDays: 5,
        previousBest: 4,
        now: now,
      )!;
      expect(milestoneLabel(m), 'Racha récord: 5 días');
      expect(streakRecordToday([m], now: now), isTrue);
      expect(
        streakRecordToday([m], now: now.add(const Duration(days: 1))),
        isFalse,
      );
    });

    test('longestStreakDays cuenta la racha más larga del historial', () {
      expect(longestStreakDays(const []), 0);
      final history = [
        _log(DateTime(2026, 11, 1, 9)),
        _log(DateTime(2026, 11, 2, 20)),
        _log(DateTime(2026, 11, 3, 8)),
        _log(DateTime(2026, 11, 3, 12)), // mismo día
        _log(DateTime(2026, 11, 7, 9)),
        _log(DateTime(2026, 11, 8, 9)),
      ];
      expect(longestStreakDays(history), 3);
    });
  });

  test('bestAccuracyOfMode combina el récord guardado y el historial', () {
    final history = [_log(now, correct: 6), _log(now, correct: 9, mode: 2)];
    expect(bestAccuracyOfMode(history, 1), 60);
    expect(bestAccuracyOfMode(history, 1, stored: 75), 75);
    expect(bestAccuracyOfMode(const [], 3), isNull);
    expect(gameSessionsOfMode(history, 1), 1);
  });

  test('Milestone ida y vuelta por JSON; JSON roto se descarta', () {
    final m = Milestone(
      kind: MilestoneKind.noteConsolidated,
      at: now,
      note: 'F#',
    );
    expect(Milestone.tryFromJson(m.toJson()), m);
    expect(Milestone.tryFromJson({'kind': 'nada', 'at': 'x'}), isNull);
  });
}
