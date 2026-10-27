import '../models/practice_session_log.dart';
import '../models/practice_session_preferences.dart';
import 'session_history_stats.dart';

/// Estado de un día en la tira semanal L–D del Home (rediseño v2, 1a).
enum WeekDayStatus {
  /// Rondas del día >= meta diaria (verde).
  completed,

  /// Entre 1 ronda y meta - 1 (ámbar).
  partial,

  /// Día pasado sin práctica, posterior a la primera práctica registrada (rojo).
  missed,

  /// Sin práctica: hoy sin rondas, días futuros o días anteriores a la
  /// primera práctica registrada (neutro).
  none,
}

/// Meta diaria por defecto para la tira semanal.
///
/// No existe una «meta diaria» propia: se usa la meta de rondas de la sesión
/// (por defecto la «Sesión de hoy», 12 rondas). Umbrales documentados:
/// - cumplido: rondas del día >= meta
/// - parcial: 1 <= rondas < meta
/// - fallado: día pasado con 0 rondas (y posterior a la primera práctica
///   registrada en el historial local)
/// - sin práctica: hoy con 0 rondas, días futuros y días previos al historial.
///
/// Si el usuario tiene una meta propia (>0) en sus preferencias, el provider
/// la usa en lugar de esta.
final int defaultDailyGoalRounds = defaultSessionRoundGoal.rounds;

/// Un día de la semana natural con su agregado y estado.
class CalendarWeekDay {
  final DateTime day;
  final int sessions;
  final int rounds;
  final int correct;
  final WeekDayStatus status;
  final bool isToday;
  final bool isFuture;

  const CalendarWeekDay({
    required this.day,
    required this.sessions,
    required this.rounds,
    required this.correct,
    required this.status,
    required this.isToday,
    required this.isFuture,
  });

  bool get hasPractice => rounds > 0;

  /// Etiqueta corta L, M, X, J, V, S, D.
  String get shortLabel => weekdayShortLabel(day);

  double get accuracyPercent => rounds > 0 ? (correct / rounds) * 100 : 0;
}

/// Siete días seguidos con su estado: la semana natural L–D que contiene
/// «hoy» ([buildCalendarWeek]) o los últimos 7 días, de hace 6 días a hoy
/// ([buildRecentDays], Home v2.1).
class CalendarWeek {
  /// Siempre 7 días, en orden cronológico.
  final List<CalendarWeekDay> days;
  final int dailyGoalRounds;

  const CalendarWeek({required this.days, required this.dailyGoalRounds});

  /// Días con al menos una ronda («5 de 7 días»).
  int get practicedDays => days.where((d) => d.hasPractice).length;

  int get completedDays =>
      days.where((d) => d.status == WeekDayStatus.completed).length;

  int get totalRounds => days.fold<int>(0, (sum, d) => sum + d.rounds);

  DateTime get monday => days.first.day;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Construye la semana natural L–D que contiene [now] a partir del historial
/// local. Las fechas de [PracticeSessionLog.endedAt] se agrupan en hora local.
///
/// [now] se inyecta siempre para que el resultado sea determinista.
CalendarWeek buildCalendarWeek(
  List<PracticeSessionLog> history, {
  required DateTime now,
  int? dailyGoalRounds,
}) {
  final goal = (dailyGoalRounds == null || dailyGoalRounds <= 0)
      ? defaultDailyGoalRounds
      : dailyGoalRounds;
  final today = _dateOnly(now);
  // DateTime normaliza días fuera de rango (p. ej. día 0 = último del mes
  // anterior) y evita los saltos de DST de `subtract(Duration(days: n))`.
  final monday =
      DateTime(today.year, today.month, today.day - (today.weekday - 1));
  return _buildDays(history, start: monday, today: today, goal: goal);
}

/// Últimos 7 días: de hace 6 días a hoy (hoy es el último). Mismas reglas
/// de estado que [buildCalendarWeek].
CalendarWeek buildRecentDays(
  List<PracticeSessionLog> history, {
  required DateTime now,
  int? dailyGoalRounds,
}) {
  final goal = (dailyGoalRounds == null || dailyGoalRounds <= 0)
      ? defaultDailyGoalRounds
      : dailyGoalRounds;
  final today = _dateOnly(now);
  final start = DateTime(today.year, today.month, today.day - 6);
  return _buildDays(history, start: start, today: today, goal: goal);
}

CalendarWeek _buildDays(
  List<PracticeSessionLog> history, {
  required DateTime start,
  required DateTime today,
  required int goal,
}) {
  final monday = start;
  final sessions = List<int>.filled(7, 0);
  final rounds = List<int>.filled(7, 0);
  final correct = List<int>.filled(7, 0);
  DateTime? firstPracticeDay;

  for (final entry in history) {
    if (entry.roundsCompleted <= 0) continue;
    final day = _dateOnly(entry.endedAt.toLocal());
    if (firstPracticeDay == null || day.isBefore(firstPracticeDay)) {
      firstPracticeDay = day;
    }
    for (var i = 0; i < 7; i++) {
      final candidate = DateTime(monday.year, monday.month, monday.day + i);
      if (candidate == day) {
        sessions[i] += 1;
        rounds[i] += entry.roundsCompleted;
        correct[i] += entry.correctRounds;
        break;
      }
    }
  }

  final days = <CalendarWeekDay>[];
  for (var i = 0; i < 7; i++) {
    final day = DateTime(monday.year, monday.month, monday.day + i);
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final dayRounds = rounds[i];

    final WeekDayStatus status;
    if (dayRounds >= goal) {
      status = WeekDayStatus.completed;
    } else if (dayRounds > 0) {
      status = WeekDayStatus.partial;
    } else if (isToday || isFuture) {
      status = WeekDayStatus.none;
    } else if (firstPracticeDay == null || day.isBefore(firstPracticeDay)) {
      status = WeekDayStatus.none;
    } else {
      status = WeekDayStatus.missed;
    }

    days.add(CalendarWeekDay(
      day: day,
      sessions: sessions[i],
      rounds: dayRounds,
      correct: correct[i],
      status: status,
      isToday: isToday,
      isFuture: isFuture,
    ));
  }

  return CalendarWeek(days: days, dailyGoalRounds: goal);
}

/// Precisión por **rondas** de la ventana actual frente a la anterior.
///
/// Base: historial local de sesiones (rondas acertadas / rondas jugadas).
/// No es la precisión global del SRS (por nota vista); la UI debe rotularlo
/// como «precisión de rondas» o usar esta misma base en el número grande.
class WeeklyAccuracyDelta {
  /// Precisión de los últimos 7 días (incluye hoy); `null` si no hay rondas.
  final double? currentPercent;

  /// Precisión de los 7 días anteriores; `null` si no hay rondas.
  final double? previousPercent;
  final int currentRounds;
  final int previousRounds;

  const WeeklyAccuracyDelta({
    required this.currentPercent,
    required this.previousPercent,
    required this.currentRounds,
    required this.previousRounds,
  });

  /// Diferencia en puntos porcentuales; `null` si falta alguna semana.
  double? get deltaPoints {
    final current = currentPercent;
    final previous = previousPercent;
    if (current == null || previous == null) return null;
    return current - previous;
  }

  bool get hasComparison => deltaPoints != null;
}

/// Calcula el delta semanal: ventana móvil de 7 días que termina hoy frente
/// a los 7 días previos. [now] se inyecta para ser determinista.
WeeklyAccuracyDelta buildWeeklyAccuracyDelta(
  List<PracticeSessionLog> history, {
  required DateTime now,
}) {
  final today = _dateOnly(now);
  final currentStart = DateTime(today.year, today.month, today.day - 6);
  final previousStart = DateTime(today.year, today.month, today.day - 13);

  var currentRounds = 0;
  var currentCorrect = 0;
  var previousRounds = 0;
  var previousCorrect = 0;

  for (final entry in history) {
    if (entry.roundsCompleted <= 0) continue;
    final day = _dateOnly(entry.endedAt.toLocal());
    if (day.isAfter(today)) continue;
    if (!day.isBefore(currentStart)) {
      currentRounds += entry.roundsCompleted;
      currentCorrect += entry.correctRounds;
    } else if (!day.isBefore(previousStart)) {
      previousRounds += entry.roundsCompleted;
      previousCorrect += entry.correctRounds;
    }
  }

  double? percent(int correct, int rounds) =>
      rounds > 0 ? (correct / rounds) * 100 : null;

  return WeeklyAccuracyDelta(
    currentPercent: percent(currentCorrect, currentRounds),
    previousPercent: percent(previousCorrect, previousRounds),
    currentRounds: currentRounds,
    previousRounds: previousRounds,
  );
}
