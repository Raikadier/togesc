import '../constants/srs_constants.dart';
import '../models/last_practice_session.dart';
import '../models/note_progress_summary.dart';
import '../models/practice_session_log.dart';
import 'srs_level.dart';

/// Nota de foco de la «Sesión de hoy» (mini-card del hero del Home).
class TodayFocusNote {
  final String note;

  /// Precisión histórica de la nota (SRS, por nota vista); `null` si aún no
  /// se ha visto nunca.
  final double? accuracyPercent;

  /// Muy atrasada (>= 3 días de retraso, `critical_notes` del SRS).
  final bool isCritical;
  final bool isOverdue;
  final bool isLearning;

  /// Nivel SRS 0..5 (ver `srsLevelFromValues`).
  final int srsLevel;

  const TodayFocusNote({
    required this.note,
    required this.accuracyPercent,
    required this.isCritical,
    required this.isOverdue,
    required this.isLearning,
    required this.srsLevel,
  });
}

/// Notas naturales, para el fallback sin datos (más fáciles de empezar).
const List<String> _naturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

/// Elige hasta [count] notas de foco, de forma determinista:
///
/// 1. Críticas (`critical_notes`), de más a menos días de retraso.
/// 2. Atrasadas ya vistas, de menor a mayor precisión.
/// 3. En aprendizaje ya vistas, de menor a mayor precisión.
/// 4. Resto de notas vistas, de menor a mayor precisión.
/// 5. Fallback sin datos: notas no vistas, naturales primero (C, D, E…) y
///    luego en orden cromático.
///
/// [criticalNotes] son pares `(nota, díasDeRetraso)` tal como los devuelve
/// `SRSSystem.getPracticeRecommendations()['critical_notes']`.
/// [allowedNotes] limita el foco al pool configurado (si no es vacío).
List<TodayFocusNote> selectTodayFocusNotes({
  required List<NoteProgressSummary> summaries,
  List<(String, int)> criticalNotes = const [],
  List<String> allowedNotes = const [],
  int count = 3,
  int learningThreshold = learningPhaseThreshold,
}) {
  if (count <= 0 || summaries.isEmpty) return const [];

  final allowed = allowedNotes.toSet();
  bool isAllowed(String note) => allowed.isEmpty || allowed.contains(note);

  final byNote = {
    for (final s in summaries)
      if (isAllowed(s.note)) s.note: s,
  };
  final criticalDays = <String, int>{
    for (final (note, days) in criticalNotes) note: days,
  };

  final chosen = <String>[];
  void take(Iterable<String> ordered) {
    for (final note in ordered) {
      if (chosen.length >= count) return;
      if (!chosen.contains(note) && byNote.containsKey(note)) chosen.add(note);
    }
  }

  int byAccuracy(NoteProgressSummary a, NoteProgressSummary b) {
    final cmp = a.accuracyPercent.compareTo(b.accuracyPercent);
    if (cmp != 0) return cmp;
    return a.note.compareTo(b.note);
  }

  final critical = criticalDays.keys.where(byNote.containsKey).toList()
    ..sort((a, b) {
      final cmp = criticalDays[b]!.compareTo(criticalDays[a]!);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
  take(critical);

  final seen = byNote.values.where((s) => s.timesSeen > 0).toList();
  take((seen.where((s) => s.isOverdue).toList()..sort(byAccuracy))
      .map((s) => s.note));
  take((seen.where((s) => s.isLearning).toList()..sort(byAccuracy))
      .map((s) => s.note));
  take((List<NoteProgressSummary>.from(seen)..sort(byAccuracy))
      .map((s) => s.note));

  final unseen = summaries
      .where((s) => s.timesSeen == 0 && isAllowed(s.note))
      .map((s) => s.note)
      .toList();
  take(_naturalNotes.where(unseen.contains));
  take(unseen);

  return [
    for (final note in chosen)
      _toFocusNote(
        byNote[note]!,
        isCritical: criticalDays.containsKey(note),
        learningThreshold: learningThreshold,
      ),
  ];
}

TodayFocusNote _toFocusNote(
  NoteProgressSummary summary, {
  required bool isCritical,
  required int learningThreshold,
}) {
  return TodayFocusNote(
    note: summary.note,
    accuracyPercent: summary.timesSeen > 0 ? summary.accuracyPercent : null,
    isCritical: isCritical,
    isOverdue: summary.isOverdue,
    isLearning: summary.isLearning,
    srsLevel: srsLevelForSummary(
      summary,
      learningThreshold: learningThreshold,
    ),
  );
}

/// Notas foco elegidas a mano (hoja «Ajustar enfoque y duración»), con sus
/// datos reales del SRS y en el orden elegido. Se ignoran las notas sin
/// resumen.
List<TodayFocusNote> buildChosenFocusNotes({
  required List<String> notes,
  required List<NoteProgressSummary> summaries,
  List<(String, int)> criticalNotes = const [],
  int learningThreshold = learningPhaseThreshold,
}) {
  final byNote = {for (final s in summaries) s.note: s};
  final critical = {for (final (note, _) in criticalNotes) note};
  return [
    for (final note in notes)
      if (byNote[note] case final summary?)
        _toFocusNote(
          summary,
          isCritical: critical.contains(note),
          learningThreshold: learningThreshold,
        ),
  ];
}

/// Lee `critical_notes` del mapa de recomendaciones del SRS de forma segura.
List<(String, int)> criticalNotesFromRecommendations(
  Map<String, dynamic> recommendations,
) {
  final raw = recommendations['critical_notes'];
  if (raw is! List) return const [];
  final result = <(String, int)>[];
  for (final item in raw) {
    if (item is (String, int)) result.add(item);
  }
  return result;
}

/// Datos de la fila «Retomar «{modo}»» del Home.
class ResumeSessionInfo {
  final PracticeKind kind;
  final int modeId;

  /// Nombre del modo para «Retomar «…»» (`LastPracticeSession.label`).
  final String label;

  /// Ruta para reabrir el modo (`/game/1`, `/speed/game/2`).
  final String route;

  /// Rondas de la última sesión registrada de ese modo; `null` si la última
  /// entrada al modo no llegó a registrar rondas (salió sin jugar).
  final int? rounds;
  final int? correctRounds;

  /// Momento de la última práctica (para «hace X»).
  final DateTime at;

  const ResumeSessionInfo({
    required this.kind,
    required this.modeId,
    required this.label,
    required this.route,
    required this.rounds,
    required this.correctRounds,
    required this.at,
  });

  LastPracticeSession get session =>
      LastPracticeSession(modeId: modeId, kind: kind, practicedAt: at);
}

/// Construye «Retomar» a partir de la última sesión abierta y del historial.
///
/// - `LastPracticeSession.practicedAt` se graba al **entrar** al modo.
/// - El historial (`PracticeSessionLog`, el más reciente primero) se graba al
///   **salir** con rondas > 0.
///
/// Se busca la entrada más reciente del historial con el mismo modo y tipo.
/// Si terminó en o después de `practicedAt`, aporta las rondas y su hora de
/// fin. Si es anterior, la última entrada al modo no jugó rondas y [rounds]
/// queda en `null` (no se muestran rondas antiguas como si fueran de ahora).
/// Sin [last], se usa la entrada más reciente del historial.
ResumeSessionInfo? buildResumeSessionInfo({
  required LastPracticeSession? last,
  required List<PracticeSessionLog> history,
}) {
  if (last == null) {
    if (history.isEmpty) return null;
    final latest = _latest(history);
    final session = LastPracticeSession(
      modeId: latest.modeId,
      kind: latest.kind,
      practicedAt: latest.endedAt,
    );
    if (session.route.isEmpty) return null;
    return ResumeSessionInfo(
      kind: latest.kind,
      modeId: latest.modeId,
      label: session.label,
      route: session.route,
      rounds: latest.roundsCompleted,
      correctRounds: latest.correctRounds,
      at: latest.endedAt,
    );
  }

  if (last.route.isEmpty) return null;

  PracticeSessionLog? match;
  for (final entry in history) {
    if (entry.modeId != last.modeId || entry.kind != last.kind) continue;
    if (match == null || entry.endedAt.isAfter(match.endedAt)) match = entry;
  }

  final PracticeSessionLog? fresh =
      (match != null && !match.endedAt.isBefore(last.practicedAt))
          ? match
          : null;
  return ResumeSessionInfo(
    kind: last.kind,
    modeId: last.modeId,
    label: last.label,
    route: last.route,
    rounds: fresh?.roundsCompleted,
    correctRounds: fresh?.correctRounds,
    at: fresh?.endedAt ?? last.practicedAt,
  );
}

PracticeSessionLog _latest(List<PracticeSessionLog> history) {
  var latest = history.first;
  for (final entry in history) {
    if (entry.endedAt.isAfter(latest.endedAt)) latest = entry;
  }
  return latest;
}
