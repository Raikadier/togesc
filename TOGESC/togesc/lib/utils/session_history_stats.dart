import '../models/practice_session_log.dart';

/// Resumen agregado de practica para un dia calendario.
class DayPracticeSummary {
  final DateTime day;
  final int sessions;
  final int rounds;
  final int correct;

  const DayPracticeSummary({
    required this.day,
    this.sessions = 0,
    this.rounds = 0,
    this.correct = 0,
  });

  double get accuracyPercent =>
      rounds > 0 ? (correct / rounds) * 100 : 0;

  bool get hasActivity => rounds > 0;
}

/// Agrega el historial local en los ultimos [days] dias (incluye hoy).
List<DayPracticeSummary> buildDailyPracticeSummaries(
  List<PracticeSessionLog> history, {
  int days = 7,
  DateTime? now,
}) {
  if (days <= 0) return [];

  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final start = today.subtract(Duration(days: days - 1));

  final buckets = <DateTime, DayPracticeSummary>{};
  for (var i = 0; i < days; i++) {
    final day = start.add(Duration(days: i));
    buckets[day] = DayPracticeSummary(day: day);
  }

  for (final entry in history) {
    final ended = entry.endedAt.toLocal();
    final day = DateTime(ended.year, ended.month, ended.day);
    final bucket = buckets[day];
    if (bucket == null) continue;

    buckets[day] = DayPracticeSummary(
      day: day,
      sessions: bucket.sessions + 1,
      rounds: bucket.rounds + entry.roundsCompleted,
      correct: bucket.correct + entry.correctRounds,
    );
  }

  return buckets.values.toList()
    ..sort((a, b) => a.day.compareTo(b.day));
}

String weekdayShortLabel(DateTime day) {
  return switch (day.weekday) {
    DateTime.monday => 'L',
    DateTime.tuesday => 'M',
    DateTime.wednesday => 'X',
    DateTime.thursday => 'J',
    DateTime.friday => 'V',
    DateTime.saturday => 'S',
    DateTime.sunday => 'D',
    _ => '?',
  };
}

/// Periodo visible en el dashboard de estadísticas.
enum StatsPeriod {
  days7,
  days30,
  all;

  String get label => switch (this) {
    StatsPeriod.days7 => '7 días',
    StatsPeriod.days30 => '30 días',
    StatsPeriod.all => 'Todo',
  };
}

/// Filtra historial a sesiones dentro del periodo (incluye hoy).
List<PracticeSessionLog> filterHistoryByPeriod(
  List<PracticeSessionLog> history,
  StatsPeriod period, {
  DateTime? now,
}) {
  if (period == StatsPeriod.all || history.isEmpty) return history;

  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final days = period == StatsPeriod.days7 ? 7 : 30;
  final start = today.subtract(Duration(days: days - 1));

  return history.where((entry) {
    final ended = entry.endedAt.toLocal();
    final day = DateTime(ended.year, ended.month, ended.day);
    return !day.isBefore(start) && !day.isAfter(today);
  }).toList();
}

/// Agrega historial según el periodo del dashboard.
List<DayPracticeSummary> buildPracticeSummariesForPeriod(
  List<PracticeSessionLog> history, {
  required StatsPeriod period,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  switch (period) {
    case StatsPeriod.days7:
      return buildDailyPracticeSummaries(history, days: 7, now: clock);
    case StatsPeriod.days30:
      return buildDailyPracticeSummaries(history, days: 30, now: clock);
    case StatsPeriod.all:
      if (history.isEmpty) {
        return buildDailyPracticeSummaries(history, days: 7, now: clock);
      }
      final earliest = history
          .map((e) => e.endedAt.toLocal())
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final today = DateTime(clock.year, clock.month, clock.day);
      final start = DateTime(earliest.year, earliest.month, earliest.day);
      final span = today.difference(start).inDays + 1;
      return buildDailyPracticeSummaries(
        history,
        days: span.clamp(7, 365),
        now: clock,
      );
  }
}

