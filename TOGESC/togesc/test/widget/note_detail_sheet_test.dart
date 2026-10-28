import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/app/app_theme.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/constants/note_naming.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/widgets/progress_v2/note_detail_sheet.dart';
import 'package:togesc/widgets/progress_v2/note_extremes.dart';
import 'package:togesc/widgets/progress_v2/progress_metrics.dart';
import 'package:togesc/widgets/session_evolution_chart.dart';

NoteProgressSummary _s(
  String note, {
  int seen = 0,
  int correct = 0,
  double latency = 0,
  bool overdue = false,
  int cc = 0,
}) =>
    NoteProgressSummary(
      note: note,
      isLearning: true,
      consecutiveCorrect: cc,
      timesSeen: seen,
      timesCorrect: correct,
      weight: 1,
      isOverdue: overdue,
      avgResponseTimeSec: latency,
    );

void main() {
  Future<({int listen, int practice})> pumpSheet(
    WidgetTester tester,
    NoteProgressSummary summary, {
    NoteNamingMode namingMode = NoteNamingMode.letter,
  }) async {
    var listen = 0;
    var practice = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NoteDetailSheet(
            summary: summary,
            namingMode: namingMode,
            onListen: () => listen++,
            onPractice: () => practice++,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('note-detail-listen')));
    await tester.tap(find.byKey(const ValueKey('note-detail-practice')));
    await tester.pump();
    return (listen: listen, practice: practice);
  }

  group('NoteDetailSheet', () {
    testWidgets('precisión, intentos, latencia, nivel, frase y acciones', (
      tester,
    ) async {
      final taps = await pumpSheet(
        tester,
        _s('C#', seen: 12, correct: 5, latency: 2.35, overdue: true, cc: 2),
      );

      expect(find.text('DETALLE DE NOTA'), findsOneWidget);
      expect(find.text('C sostenido'), findsOneWidget);
      expect(find.text('Crítica · pendiente de repaso'), findsOneWidget);
      expect(find.text('42 %'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('2,4 s'), findsOneWidget);
      expect(find.text('Nivel SRS 1 de 5'), findsOneWidget);
      expect(
        find.text(noteDetailAdvice(MasteryStatus.critical)),
        findsOneWidget,
      );
      expect(taps.listen, 1);
      expect(taps.practice, 1);
      expect(
        find.bySemanticsLabel('Latencia: 2,4 s'),
        findsOneWidget,
      );
    });

    testWidgets('nota sin datos: «—» y frase de inicio', (tester) async {
      await pumpSheet(tester, _s('D'), namingMode: NoteNamingMode.solfege);
      expect(find.text('Re'), findsWidgets);
      expect(find.text('Sin datos'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text(noteDetailAdvice(MasteryStatus.unseen)), findsOneWidget);
    });

    testWidgets('a 320 px no desborda', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpSheet(tester, _s('A#', seen: 1234, correct: 600, latency: 12.3));
      expect(tester.takeException(), isNull);
    });

    test('una frase distinta por estado', () {
      final phrases = MasteryStatus.values.map(noteDetailAdvice).toSet();
      expect(phrases, hasLength(MasteryStatus.values.length));
    });
  });

  group('noteExtremes', () {
    test('3 más difíciles y 3 más fáciles, sin repetir', () {
      final summaries = [
        for (final (note, correct) in [
          ('C', 2),
          ('D', 5),
          ('E', 7),
          ('F', 8),
          ('G', 9),
          ('A', 10),
          ('B', 6),
        ])
          _s(note, seen: 10, correct: correct),
        _s('C#'),
      ];
      final ex = noteExtremes(summaries);
      expect(ex.hardest.map((s) => s.note), ['C', 'D', 'B']);
      expect(ex.easiest.map((s) => s.note), ['A', 'G', 'F']);
    });

    test('con pocas notas vistas no se solapan', () {
      final ex = noteExtremes([
        _s('C', seen: 10, correct: 2),
        _s('D', seen: 10, correct: 9),
        _s('E', seen: 10, correct: 5),
      ]);
      expect(ex.hardest.map((s) => s.note), ['C']);
      expect(ex.easiest.map((s) => s.note), ['D']);
    });

    test('menos de dos notas vistas: sin extremos', () {
      final ex = noteExtremes([_s('C', seen: 3, correct: 1), _s('D')]);
      expect(ex.hardest, isEmpty);
      expect(ex.easiest, isEmpty);
    });
  });

  group('SessionAccuracyBars', () {
    PracticeSessionLog log(int day, int correct) => PracticeSessionLog(
          modeId: GameMode.singleNote.id,
          kind: PracticeKind.game,
          roundsCompleted: 10,
          correctRounds: correct,
          endedAt: DateTime(2026, 10, day, 12),
        );

    test('las 8 más recientes, de la más antigua a la más reciente', () {
      final entries = [for (var d = 1; d <= 10; d++) log(d, d)];
      final visible = SessionAccuracyBars.visible(entries.reversed.toList());
      expect(visible, hasLength(8));
      expect(visible.first.endedAt.day, 3);
      expect(visible.last.endedAt.day, 10);
    });

    test('texto alternativo con cada sesión', () {
      final text = SessionAccuracyBars.semanticsFor([log(8, 8), log(9, 6)]);
      expect(
        text,
        'Precisión por sesión, de la más antigua a la más reciente: '
        'Una sola nota, 8/10, 80 %; Una sola nota, 9/10, 60 %',
      );
    });

    testWidgets('verde a partir del 75 % y sin animación pendiente con '
        'movimiento reducido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SessionAccuracyBars(entries: [log(8, 8), log(9, 6)]),
            ),
          ),
        ),
      );
      expect(find.text('80'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(await tester.pumpAndSettle(), 1);
    });
  });
}
