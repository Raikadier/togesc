import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/notes.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';

void main() {
  group('buildNoteProgressSummaries', () {
    late SRSSystem srs;

    setUp(() async {
      srs = SRSSystem(
        repository: InMemoryProgressRepository(),
        random: Random(1),
        clock: () => DateTime(2026, 6, 15),
      );
      await srs.loadProgress();
    });

    test('devuelve 12 notas en orden cromatico', () {
      final summaries = buildNoteProgressSummaries(srs);
      expect(summaries.length, notes.length);
      expect(summaries.map((s) => s.note).toList(), notes.keys.toList());
    });

    test('refleja datos SRS de una nota', () {
      srs.noteData['C']!
        ..timesSeen = 10
        ..timesCorrect = 8
        ..consecutiveCorrect = 3
        ..isLearning = true;

      final summary = buildNoteProgressSummaries(srs).first;
      expect(summary.note, 'C');
      expect(summary.timesSeen, 10);
      expect(summary.timesCorrect, 8);
      expect(summary.accuracyPercent, 80);
      expect(summary.isLearning, isTrue);
    });
  });

  group('NoteProgressSummary', () {
    test('statusLabel segun fase', () {
      const learning = NoteProgressSummary(
        note: 'D',
        isLearning: true,
        consecutiveCorrect: 2,
        timesSeen: 5,
        timesCorrect: 3,
        weight: 10,
        isOverdue: false,
      );
      expect(learning.statusLabel, 'En aprendizaje');

      const consolidated = NoteProgressSummary(
        note: 'D',
        isLearning: false,
        consecutiveCorrect: 5,
        timesSeen: 20,
        timesCorrect: 18,
        weight: 2,
        isOverdue: false,
      );
      expect(consolidated.statusLabel, 'Consolidada');
    });
  });
}
