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
