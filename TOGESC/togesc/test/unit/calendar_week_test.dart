import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/utils/calendar_week.dart';

PracticeSessionLog _log(DateTime endedAt, int rounds, [int? correct]) {
  return PracticeSessionLog(
    modeId: 1,
    kind: PracticeKind.game,
    roundsCompleted: rounds,
    correctRounds: correct ?? rounds,
    endedAt: endedAt,
  );
}

void main() {
  // Viernes 9 de octubre de 2026, 18:00 (hora local).
  final now = DateTime(2026, 10, 9, 18);

  group('buildCalendarWeek', () {
    test('semana natural lunes a domingo que contiene hoy', () {
      final week = buildCalendarWeek(const [], now: now);
      expect(week.days, hasLength(7));
      expect(week.monday, DateTime(2026, 10, 5));
      expect(week.days.last.day, DateTime(2026, 10, 11));
      expect(
        week.days.map((d) => d.shortLabel).join(),
        'LMXJVSD',
      );
      expect(week.days[4].isToday, isTrue);
      expect(week.days[5].isFuture, isTrue);
      expect(week.dailyGoalRounds, 12);
    });

    test('historial vacio: todo sin practica', () {
      final week = buildCalendarWeek(const [], now: now);
      expect(
        week.days.every((d) => d.status == WeekDayStatus.none),
        isTrue,
      );
      expect(week.practicedDays, 0);
    });

    test('cumplido, parcial, fallado y sin practica', () {
      final history = [
        _log(DateTime(2026, 10, 5, 9), 12), // L: cumplido
        _log(DateTime(2026, 10, 6, 9), 4), // M: parcial
        _log(DateTime(2026, 10, 6, 20), 3), // M: suma 7, parcial
        // X (7): sin practica, pasado -> fallado
        _log(DateTime(2026, 10, 8, 9), 8), // J: parcial
        _log(DateTime(2026, 10, 8, 21), 5), // J: suma 13, cumplido
        // V (hoy) sin rondas -> sin practica
      ];
      final week = buildCalendarWeek(history, now: now);
      final status = week.days.map((d) => d.status).toList();
      expect(status, [
        WeekDayStatus.completed,
        WeekDayStatus.partial,
        WeekDayStatus.missed,
        WeekDayStatus.completed,
        WeekDayStatus.none,
        WeekDayStatus.none,
        WeekDayStatus.none,
      ]);
      expect(week.days[1].rounds, 7);
      expect(week.days[1].sessions, 2);
      expect(week.practicedDays, 3);
      expect(week.completedDays, 2);
      expect(week.totalRounds, 32);
    });

    test('dias anteriores a la primera practica no cuentan como fallados',
        () {
      final history = [_log(DateTime(2026, 10, 7, 10), 2)];
      final week = buildCalendarWeek(history, now: now);
      expect(week.days[0].status, WeekDayStatus.none); // L
      expect(week.days[1].status, WeekDayStatus.none); // M
      expect(week.days[2].status, WeekDayStatus.partial); // X
      expect(week.days[3].status, WeekDayStatus.missed); // J
    });

    test('practica de semanas anteriores marca fallados los dias vacios', () {
      final history = [_log(DateTime(2026, 9, 28, 10), 12)];
      final week = buildCalendarWeek(history, now: now);
      expect(
        week.days.take(4).every((d) => d.status == WeekDayStatus.missed),
        isTrue,
      );
    });

    test('hoy con rondas suficientes queda cumplido', () {
      final history = [_log(DateTime(2026, 10, 9, 8), 12)];
      final week = buildCalendarWeek(history, now: now);
      expect(week.days[4].status, WeekDayStatus.completed);
    });

    test('meta diaria personalizada', () {
      final history = [_log(DateTime(2026, 10, 9, 8), 5)];
      final week = buildCalendarWeek(history, now: now, dailyGoalRounds: 5);
      expect(week.days[4].status, WeekDayStatus.completed);
      expect(week.dailyGoalRounds, 5);
    });

    test('meta no valida usa la de por defecto', () {
      final week = buildCalendarWeek(const [], now: now, dailyGoalRounds: 0);
      expect(week.dailyGoalRounds, defaultDailyGoalRounds);
    });

    test('domingo pertenece a la semana que empieza el lunes anterior', () {
      final sunday = DateTime(2026, 10, 11, 23, 59);
      final week = buildCalendarWeek(const [], now: sunday);
      expect(week.monday, DateTime(2026, 10, 5));
      expect(week.days.last.isToday, isTrue);
    });

    test('semana que cruza de mes', () {
      final week = buildCalendarWeek(const [], now: DateTime(2026, 10, 1, 12));
      expect(week.monday, DateTime(2026, 9, 28));
      expect(week.days.last.day, DateTime(2026, 10, 4));
    });
  });

  group('buildWeeklyAccuracyDelta', () {
    test('compara los ultimos 7 dias con los 7 anteriores', () {
      final history = [
        _log(DateTime(2026, 10, 9, 10), 10, 8), // actual
        _log(DateTime(2026, 10, 3, 10), 10, 6), // actual (hoy - 6)
        _log(DateTime(2026, 10, 2, 10), 10, 5), // anterior (hoy - 7)
        _log(DateTime(2026, 9, 26, 10), 10, 7), // anterior (hoy - 13)
        _log(DateTime(2026, 9, 25, 10), 10, 0), // fuera de rango
      ];
      final delta = buildWeeklyAccuracyDelta(history, now: now);
      expect(delta.currentRounds, 20);
      expect(delta.previousRounds, 20);
      expect(delta.currentPercent, closeTo(70, 0.001));
      expect(delta.previousPercent, closeTo(60, 0.001));
      expect(delta.deltaPoints, closeTo(10, 0.001));
      expect(delta.hasComparison, isTrue);
    });

    test('sin semana anterior no hay delta', () {
      final history = [_log(DateTime(2026, 10, 9, 10), 4, 3)];
      final delta = buildWeeklyAccuracyDelta(history, now: now);
      expect(delta.currentPercent, closeTo(75, 0.001));
      expect(delta.previousPercent, isNull);
      expect(delta.deltaPoints, isNull);
      expect(delta.hasComparison, isFalse);
    });

    test('historial vacio', () {
      final delta = buildWeeklyAccuracyDelta(const [], now: now);
      expect(delta.currentPercent, isNull);
      expect(delta.previousPercent, isNull);
      expect(delta.deltaPoints, isNull);
    });

    test('sesiones futuras se ignoran', () {
      final history = [_log(DateTime(2026, 10, 10, 10), 10, 10)];
      final delta = buildWeeklyAccuracyDelta(history, now: now);
      expect(delta.currentRounds, 0);
    });
  });
}
