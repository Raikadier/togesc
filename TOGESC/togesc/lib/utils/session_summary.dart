import 'package:flutter/material.dart';

import '../constants/srs_constants.dart';
import '../models/last_practice_session.dart';
import '../models/note_progress_summary.dart';
import '../models/practice_session_log.dart';
import 'number_format.dart';
import 'srs_level.dart';
export 'number_format.dart' show formatSecondsEs;

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

  /// Intentos acumulados tras la sesión; `null` si no se conocen.
  final int? timesSeenAfter;

  const SessionLevelChange({
    required this.note,
    required this.before,
    required this.after,
    required this.accuracyBefore,
    required this.accuracyAfter,
    this.timesSeenAfter,
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
        timesSeenAfter: a.timesSeen,
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
  if (up == 0) return 'Las notas que fallaste volverán antes.';
  if (up == 1) return '1 nota subió de nivel.';
  return '$up notas subieron de nivel.';
}

// --- v2.2, lote C: el resumen dice qué ha pasado y qué viene después ---

/// Las tres primeras sesiones son mediciones: aún no hay datos para juzgar.
bool isMeasuringSession(int? sessionNumber) =>
    sessionNumber != null && sessionNumber >= 1 && sessionNumber <= 3;

/// Titular del resumen. En las tres primeras sesiones no se valora la
/// precisión; después, la medalla de v2.1.
String sessionHeadline({
  required int? sessionNumber,
  required double accuracyPercent,
}) {
  return switch (sessionNumber) {
    1 => 'Primera medición hecha',
    2 => 'Segunda medición hecha',
    3 => 'Tercera medición hecha',
    _ => SessionMedal.forAccuracy(accuracyPercent).headline,
  };
}

/// Precisión de la última sesión de práctica del mismo modo; `null` si no
/// hay ninguna. No depende del orden de [history].
double? previousSessionAccuracy(
  List<PracticeSessionLog> history, {
  required int modeId,
}) {
  PracticeSessionLog? last;
  for (final e in history) {
    if (e.modeId != modeId ||
        e.kind != PracticeKind.game ||
        e.roundsCompleted <= 0) {
      continue;
    }
    if (last == null || e.endedAt.isAfter(last.endedAt)) last = e;
  }
  return last?.accuracyPercent;
}

/// Precisión de la última sesión terminada hoy; `null` si hoy no hay ninguna.
double? lastAccuracyToday(
  List<PracticeSessionLog> history, {
  required DateTime now,
}) {
  PracticeSessionLog? last;
  for (final e in history) {
    final d = e.endedAt.toLocal();
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    if (!sameDay || e.roundsCompleted <= 0) continue;
    if (last == null || e.endedAt.isAfter(last.endedAt)) last = e;
  }
  return last?.accuracyPercent;
}

/// «5 puntos más que la última vez». `null` si no hay sesión anterior.
String? sessionDeltaLine({
  required double accuracyPercent,
  required double? previousAccuracyPercent,
}) {
  if (previousAccuracyPercent == null) return null;
  final diff = accuracyPercent.round() - previousAccuracyPercent.round();
  if (diff == 0) return 'Igual que la última vez.';
  final points = plural(diff.abs(), 'punto', 'puntos');
  return diff > 0
      ? '$points más que la última vez.'
      : '$points menos que la última vez.';
}

/// «Próxima sesión: Fa, La# y Si.» con las notas que el repaso prioriza
/// ahora. No dice «mañana»: el foco se recalcula al abrir la app.
String nextSessionLine(List<String> noteLabels) {
  if (noteLabels.isEmpty) return 'Próxima sesión: notas nuevas.';
  const shown = 3;
  final head = noteLabels.take(shown).toList();
  final rest = noteLabels.length - head.length;
  final String list;
  if (rest > 0) {
    list = '${head.join(', ')} y $rest más';
  } else if (head.length == 1) {
    list = head.single;
  } else {
    list = '${head.sublist(0, head.length - 1).join(', ')} y ${head.last}';
  }
  return 'Próxima sesión: $list.';
}

/// «Tu mejor racha: 5 seguidas.» desde 3 aciertos seguidos; si no, `null`.
String? bestStreakLine(int bestStreak) =>
    bestStreak >= 3 ? 'Tu mejor racha: $bestStreak seguidas.' : null;
