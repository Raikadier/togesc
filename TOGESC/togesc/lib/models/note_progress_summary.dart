import '../constants/notes.dart';
import '../constants/srs_constants.dart';
import '../models/note_data.dart';
import '../services/srs_system.dart';

/// Resumen SRS de una nota para la UI de progreso detallado.
class NoteProgressSummary {
  final String note;
  final bool isLearning;
  final int consecutiveCorrect;
  final int timesSeen;
  final int timesCorrect;
  final double weight;
  final bool isOverdue;
  final double avgResponseTimeSec;

  const NoteProgressSummary({
    required this.note,
    required this.isLearning,
    required this.consecutiveCorrect,
    required this.timesSeen,
    required this.timesCorrect,
    required this.weight,
    required this.isOverdue,
    this.avgResponseTimeSec = 0,
  });

  double get accuracyPercent =>
      timesSeen > 0 ? (timesCorrect / timesSeen) * 100 : 0;

  String get statusLabel =>
      isLearning ? 'En aprendizaje' : 'Consolidada';

  factory NoteProgressSummary.fromSrs({
    required String note,
    required NoteData data,
    required bool isOverdue,
  }) {
    return NoteProgressSummary(
      note: note,
      isLearning: data.isLearning,
      consecutiveCorrect: data.consecutiveCorrect,
      timesSeen: data.timesSeen,
      timesCorrect: data.timesCorrect,
      weight: data.weight,
      isOverdue: isOverdue,
      avgResponseTimeSec: data.avgResponseTimeSec,
    );
  }
}

/// Las 12 notas en orden cromatico con estado SRS actual.
List<NoteProgressSummary> buildNoteProgressSummaries(SRSSystem srs) {
  final overdue = srs.getOverdueNotes().toSet();
  return notes.keys
      .map(
        (note) => NoteProgressSummary.fromSrs(
          note: note,
          data: srs.noteData[note]!,
          isOverdue: overdue.contains(note),
        ),
      )
      .toList();
}

int get learningGraduationThreshold => learningPhaseThreshold;
