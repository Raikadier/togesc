import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../constants/note_naming.dart';
import '../models/last_practice_session.dart';
import '../models/note_progress_summary.dart';
import '../models/practice_session_log.dart';
import '../widgets/progress_v2/progress_metrics.dart';
import 'number_format.dart';
import 'session_summary.dart';

/// Hitos reales (v2.2, lote D): solo hechos que el historial demuestra.
enum MilestoneKind {
  noteConsolidated,
  bestSession,
  streakRecord,
  octaveComplete,
}

@immutable
class Milestone {
  final MilestoneKind kind;
  final DateTime at;

  /// Nota (en letra) del hito «consolidada».
  final String? note;

  /// Precisión redondeada (mejor sesión) o días (racha récord).
  final int? value;

  const Milestone({
    required this.kind,
    required this.at,
    this.note,
    this.value,
  });

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'at': at.toIso8601String(),
    if (note != null) 'note': note,
    if (value != null) 'value': value,
  };

  /// `null` si el JSON no es un hito válido (datos guardados corruptos).
  static Milestone? tryFromJson(Map<String, dynamic> json) {
    final kind = MilestoneKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final at = DateTime.tryParse('${json['at']}');
    if (kind == null || at == null) return null;
    final note = json['note'];
    final value = json['value'];
    return Milestone(
      kind: kind,
      at: at,
      note: note is String ? note : null,
      value: value is int ? value : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Milestone &&
      other.kind == kind &&
      other.at == at &&
      other.note == note &&
      other.value == value;

  @override
  int get hashCode => Object.hash(kind, at, note, value);
}

/// Texto del hito. En el resumen la mejor sesión se dice «Tu mejor sesión
/// hasta hoy»; en el Perfil lleva la cifra.
String milestoneLabel(
  Milestone m, {
  NoteNamingMode namingMode = NoteNamingMode.letter,
  bool inSummary = false,
}) {
  return switch (m.kind) {
    MilestoneKind.noteConsolidated =>
      '${formatNoteLabel(m.note ?? '', namingMode)}, consolidada',
    MilestoneKind.bestSession =>
      inSummary || m.value == null
          ? 'Tu mejor sesión hasta hoy'
          : 'Mejor sesión: ${m.value} %',
    MilestoneKind.streakRecord =>
      m.value == null
          ? 'Racha récord'
          : 'Racha récord: ${plural(m.value!, 'día', 'días')}',
    MilestoneKind.octaveComplete => 'Octava completa',
  };
}

bool _mastered(NoteSrsSnapshot s) =>
    masteryStatusOf(timesSeen: s.timesSeen, pct: s.accuracyPercent ?? 0) ==
    MasteryStatus.mastered;

/// Hitos de una sesión de práctica.
///
/// - [before]: estado de las notas al empezar; vacío si no se conoce, y
///   entonces no se declara ninguna nota nueva.
/// - [previousSessionsSameMode] y [previousBestAccuracy]: sesiones y mejor
///   precisión anteriores del mismo modo, sin contar esta.
List<Milestone> sessionMilestones({
  required Map<String, NoteSrsSnapshot> before,
  required List<NoteProgressSummary> after,
  required int roundsCompleted,
  required int correctRounds,
  required int previousSessionsSameMode,
  required double? previousBestAccuracy,
  required DateTime now,
}) {
  if (roundsCompleted <= 0) return const [];
  final out = <Milestone>[];

  if (before.isNotEmpty) {
    final masteredAfter = {
      for (final s in after)
        if (masteryStatusFor(s) == MasteryStatus.mastered) s.note,
    };
    for (final note in chromaticNotes) {
      final b = before[note];
      if (masteredAfter.contains(note) && (b == null || !_mastered(b))) {
        out.add(
          Milestone(kind: MilestoneKind.noteConsolidated, at: now, note: note),
        );
      }
    }
    final wasComplete = chromaticNotes.every(
      (n) => before[n] != null && _mastered(before[n]!),
    );
    if (!wasComplete && chromaticNotes.every(masteredAfter.contains)) {
      out.add(Milestone(kind: MilestoneKind.octaveComplete, at: now));
    }
  }

  final accuracy = (correctRounds / roundsCompleted * 100).round();
  if (previousSessionsSameMode >= 3 &&
      previousBestAccuracy != null &&
      accuracy > previousBestAccuracy.round()) {
    out.add(
      Milestone(kind: MilestoneKind.bestSession, at: now, value: accuracy),
    );
  }
  return out;
}

/// Notas consolidadas al empezar la sesión.
int consolidatedBeforeCount(Map<String, NoteSrsSnapshot> before) =>
    before.values.where(_mastered).length;

/// Sesiones de práctica del mismo modo en [history] (con rondas).
int gameSessionsOfMode(List<PracticeSessionLog> history, int modeId) => history
    .where(
      (e) =>
          e.modeId == modeId &&
          e.kind == PracticeKind.game &&
          e.roundsCompleted > 0,
    )
    .length;

/// Mejor precisión anterior del modo: la guardada ([stored], que sobrevive
/// al límite de 50 sesiones del historial) o la del historial si es mayor.
double? bestAccuracyOfMode(
  List<PracticeSessionLog> history,
  int modeId, {
  double? stored,
}) {
  double? best = stored;
  for (final e in history) {
    if (e.modeId != modeId ||
        e.kind != PracticeKind.game ||
        e.roundsCompleted <= 0) {
      continue;
    }
    best = best == null ? e.accuracyPercent : math.max(best, e.accuracyPercent);
  }
  return best;
}

/// Racha de días más larga que contiene [history].
int longestStreakDays(List<PracticeSessionLog> history) {
  final days = {
    for (final e in history)
      if (e.roundsCompleted > 0)
        DateTime(
          e.endedAt.toLocal().year,
          e.endedAt.toLocal().month,
          e.endedAt.toLocal().day,
        ),
  }.toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? prev;
  for (final d in days) {
    // Por calendario y no por horas: los cambios de hora no rompen la racha.
    final next = prev == null
        ? null
        : DateTime(prev.year, prev.month, prev.day + 1);
    run = next == d ? run + 1 : 1;
    best = math.max(best, run);
    prev = d;
  }
  return best;
}

/// Racha récord: desde 2 días y por encima de la mejor anterior.
Milestone? streakRecordMilestone({
  required int streakDays,
  required int previousBest,
  required DateTime now,
}) {
  if (streakDays < 2 || streakDays <= previousBest) return null;
  return Milestone(
    kind: MilestoneKind.streakRecord,
    at: now,
    value: streakDays,
  );
}

/// Hoy se batió la racha récord (el chip del Home dice «Récord»).
bool streakRecordToday(List<Milestone> log, {required DateTime now}) =>
    log.any((m) {
      if (m.kind != MilestoneKind.streakRecord) return false;
      final d = m.at.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    });
