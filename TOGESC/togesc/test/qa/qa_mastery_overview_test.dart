import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/app/app_theme.dart';
import 'package:togesc/constants/notes.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/widgets/progress_v2/mastery_overview.dart';

import 'qa_support.dart';

/// Rueda «Dominio por nota» de Progreso: centro y subtítulo cuentan
/// «consolidadas» y deben decir lo mismo para los mismos datos.
void main() {
  NoteProgressSummary summary(
    String note, {
    bool isLearning = true,
    int seen = 0,
    int correct = 0,
  }) => NoteProgressSummary(
    note: note,
    isLearning: isLearning,
    consecutiveCorrect: 0,
    timesSeen: seen,
    timesCorrect: correct,
    weight: 1,
    isOverdue: false,
  );

  /// Como `StatisticsScreen` (l.114-125): subtítulo = `graduated` del SRS
  /// (notas fuera de la fase de aprendizaje) y «en curso» = `learning_phase`.
  Future<(String, String)> pumpWith(
    WidgetTester tester,
    List<NoteProgressSummary> summaries,
  ) async {
    final graduated = summaries.where((s) => !s.isLearning).length;
    final learning = summaries.length - graduated;
    await tester.binding.setSurfaceSize(const Size(420, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MasteryOverview(
              summaries: summaries,
              consolidatedCount: graduated,
              inProgressCount: learning,
              onNoteTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final center = find.textContaining(RegExp(r'^\d+/12$'));
    expect(center, findsOneWidget);
    final subtitle = tester
        .widget<Text>(find.byKey(const Key('progress-mastery-subtitle')))
        .data!;
    final centerValue = tester.widget<Text>(center).data!.split('/').first;
    final subtitleValue = subtitle.split(' ').first;
    return (centerValue, subtitleValue);
  }

  testWidgets('usuario nuevo: 0 y 0 (control)', (tester) async {
    final (center, sub) = await pumpWith(tester, [
      for (final n in notes.keys) summary(n),
    ]);
    expect(center, '0');
    expect(sub, '0');
  });

  testWidgets('el centro y el subtítulo «consolidadas» coinciden '
      '[BUG: mastery_overview.dart:63/71 pinta en el centro '
      'consolidatedNoteCount (precisión ≥ 75 %) y en l.115 el subtítulo usa '
      'consolidatedCount (graduadas por SRS)]', (tester) async {
    final (center, sub) = await pumpWith(tester, [
      for (final n in notes.keys)
        switch (n) {
          // 4/4 pero aún en aprendizaje: cuenta en el centro, no en el SRS.
          'C' => summary(n, seen: 4, correct: 4),
          // Graduadas con precisión baja: cuentan en el SRS, no en el centro.
          'D' || 'E' => summary(n, isLearning: false, seen: 10, correct: 5),
          _ => summary(n),
        },
    ]);
    expect(center, sub, reason: 'centro $center/12 vs «$sub consolidadas»');
  }, skip: qaSkipBug);
}
