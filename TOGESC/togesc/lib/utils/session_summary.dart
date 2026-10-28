import 'package:flutter/material.dart';

import '../constants/srs_constants.dart';
import '../models/note_progress_summary.dart';
import 'srs_level.dart';

/// Estado SRS de una nota al empezar la sesión (para el resumen final).
@immutable
class NoteSrsSnapshot {
  final int level;

  /// Precisión histórica; `null` si aún no se había visto.
  final double? accuracyPercent;
  final int timesSeen;

  const NoteSrsSnapshot({
    required this.level,
    required this.accuracyPercent,
    required this.timesSeen,
  });

  factory NoteSrsSnapshot.fromSummary(
    NoteProgressSummary summary, {
    int learningThreshold = learningPhaseThreshold,
  }) {
    return NoteSrsSnapshot(
      level: srsLevelForSummary(summary, learningThreshold: learningThreshold),
      accuracyPercent:
          summary.timesSeen > 0 ? summary.accuracyPercent : null,
      timesSeen: summary.timesSeen,
    );
  }
}

/// Instantánea de todas las notas, por nota.
Map<String, NoteSrsSnapshot> snapshotSrs(
  List<NoteProgressSummary> summaries, {
  int learningThreshold = learningPhaseThreshold,
}) {
  return {
    for (final s in summaries)
      s.note: NoteSrsSnapshot.fromSummary(
        s,
        learningThreshold: learningThreshold,
      ),
  };
}

/// Cambio de nivel SRS de una nota entre el inicio y el final de la sesión.
@immutable
class SessionLevelChange {
  final String note;
  final int before;
  final int after;
  final double? accuracyBefore;
  final double? accuracyAfter;

  const SessionLevelChange({
    required this.note,
    required this.before,
    required this.after,
    required this.accuracyBefore,
    required this.accuracyAfter,
  });

  int get delta => after - before;
  bool get improved => after > before;
  bool get dropped => after < before;
}

/// Filas «Cambios de nivel SRS» del resumen: una por nota que salió en la
/// sesión ([sessionNotes]), con su nivel al empezar ([before]) y ahora
/// ([after]). Orden: las que más subieron primero; a igualdad, orden
/// cromático (el de [chromaticOrder]). Las notas sin datos en alguno de los
/// dos lados se omiten.
List<SessionLevelChange> buildSessionLevelChanges({
  required Map<String, NoteSrsSnapshot> before,
  required List<NoteProgressSummary> after,
  required Iterable<String> sessionNotes,
  List<String> chromaticOrder = const [],
  int learningThreshold = learningPhaseThreshold,
}) {
  final now = snapshotSrs(after, learningThreshold: learningThreshold);
  final changes = <SessionLevelChange>[];
  for (final note in sessionNotes.toSet()) {
    final b = before[note];
    final a = now[note];
    if (b == null || a == null) continue;
    changes.add(
      SessionLevelChange(
        note: note,
        before: b.level,
        after: a.level,
        accuracyBefore: b.accuracyPercent,
        accuracyAfter: a.accuracyPercent,
      ),
    );
  }
  int order(String n) {
    final i = chromaticOrder.indexOf(n);
    return i < 0 ? chromaticOrder.length : i;
  }

  changes.sort((x, y) {
    final cmp = y.delta.compareTo(x.delta);
    if (cmp != 0) return cmp;
    final o = order(x.note).compareTo(order(y.note));
    return o != 0 ? o : x.note.compareTo(y.note);
  });
  return changes;
}

/// Tiempo medio de respuesta en segundos; `null` sin respuestas medidas.
/// Ignora los valores no positivos (respuestas sin cronómetro).
double? averageResponseTimeSec(Iterable<double> times) {
  final valid = times.where((t) => t > 0).toList();
  if (valid.isEmpty) return null;
  return valid.reduce((a, b) => a + b) / valid.length;
}

/// Medalla del resumen según la precisión de la sesión (SPEC v2.1 §2.2.7).
enum SessionMedal {
  great(Icons.military_tech_rounded, 'Gran oído hoy'),
  good(Icons.workspace_premium_rounded, 'Vas por buen camino'),
  keepGoing(Icons.self_improvement_rounded, 'Cada fallo afina el repaso');

  const SessionMedal(this.icon, this.headline);

  final IconData icon;
  final String headline;

  static SessionMedal forAccuracy(double accuracyPercent) {
    if (accuracyPercent >= 75) return great;
    if (accuracyPercent >= 50) return good;
    return keepGoing;
  }
}

/// Frase bajo el titular del resumen, solo con datos reales.
String sessionSummaryLead(List<SessionLevelChange> changes) {
  final up = changes.where((c) => c.improved).length;
  if (up == 0) return 'El SRS repetirá antes las notas que fallaste.';
  if (up == 1) return '1 nota subió de nivel SRS.';
  return '$up notas subieron de nivel SRS.';
}

/// «2,4 s» (es-ES, un decimal).
String formatSecondsEs(double seconds) =>
    '${seconds.toStringAsFixed(1).replaceAll('.', ',')} s';
