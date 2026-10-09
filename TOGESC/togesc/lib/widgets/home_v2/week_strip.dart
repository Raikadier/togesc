import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../utils/calendar_week.dart';
import '../../utils/relative_time.dart';

/// Texto de estado de un día para lectores de pantalla y leyenda.
String weekDayStatusLabel(WeekDayStatus status) => switch (status) {
      WeekDayStatus.completed => 'meta cumplida',
      WeekDayStatus.partial => 'práctica parcial',
      WeekDayStatus.missed => 'sin practicar',
      WeekDayStatus.none => 'sin práctica',
    };

/// Etiqueta semántica completa de un día («Lunes, hoy: práctica parcial,
/// 5 de 12 rondas»). El color nunca es la única señal: cada celda lleva
/// además un icono y esta etiqueta.
String weekDaySemanticsLabel(CalendarWeekDay day, int goal) {
  final buffer = StringBuffer(weekdayLongLabelEs(day.day));
  if (day.isToday) buffer.write(', hoy');
  if (day.isFuture) {
    buffer.write(': día futuro');
    return buffer.toString();
  }
  buffer.write(': ${weekDayStatusLabel(day.status)}');
  if (day.rounds > 0) buffer.write(', ${day.rounds} de $goal rondas');
  return buffer.toString();
}

/// Sección «Esta semana · N de 7 días» con 7 celdas L–D de 44 de alto.
class WeekStrip extends StatelessWidget {
  final CalendarWeek week;

  const WeekStrip({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('home-week-strip'),
      children: [
        for (var i = 0; i < week.days.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _WeekDayCell(
              day: week.days[i],
              goal: week.dailyGoalRounds,
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  final CalendarWeekDay day;
  final int goal;

  const _WeekDayCell({required this.day, required this.goal});

  @override
  Widget build(BuildContext context) {
    final colors = TogescColors.of(context);
    // Los rellenos de estado (verde, ámbar y rojo claro) llevan su propio
    // texto AA y valen en ambos temas. El día sin práctica usa la
    // superficie apagada del tema: #F3ECF1 en claro y #241B2A en oscuro.
    final (Color bg, Color fg, IconData? icon) = switch (day.status) {
      WeekDayStatus.completed => (
          DesignTokens.masteryGreenLight,
          DesignTokens.onSurface,
          Icons.check_rounded,
        ),
      WeekDayStatus.partial => (
          DesignTokens.warningLight,
          DesignTokens.onWarning,
          Icons.timelapse_rounded,
        ),
      WeekDayStatus.missed => (
          DesignTokens.criticalBar,
          DesignTokens.onSurface,
          Icons.close_rounded,
        ),
      WeekDayStatus.none => (
          colors.muted,
          colors.textSecondary,
          null,
        ),
    };

    return Semantics(
      key: ValueKey('week-day-${day.day.weekday}'),
      label: weekDaySemanticsLabel(day, goal),
      excludeSemantics: true,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: DesignTokens.borderRadiusCell,
          border: day.isToday
              ? Border.all(color: colors.brand, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.shortLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1.1,
              ),
            ),
            if (icon != null)
              Icon(icon, size: 14, color: fg)
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
