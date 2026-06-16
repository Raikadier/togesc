import '../services/srs_system.dart';

/// Exporta progreso SRS a CSV (funcion Pro).
abstract final class ProgressExportService {
  static String buildCsv(SRSSystem srs) {
    final buffer = StringBuffer()
      ..writeln(
        'nota,peso,en_aprendizaje,aciertos_segidos,vistas,aciertos,ease_factor',
      );

    for (final entry in srs.noteData.entries) {
      final note = entry.key;
      final data = entry.value;
      buffer.writeln(
        [
          _escape(note),
          data.weight.toStringAsFixed(2),
          data.isLearning ? 'si' : 'no',
          data.consecutiveCorrect,
          data.timesSeen,
          data.timesCorrect,
          data.easeFactor.toStringAsFixed(2),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
