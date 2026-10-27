import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/togesc_colors.dart';
import '../../providers/today_session_provider.dart';
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

/// Frase de racha bajo la tira de días (SPEC v2.1 §2.1.4).
String weekStreakCopy(HomeStreakStatus status) {
  final days = status.days == 1 ? '1 día' : '${status.days} días';
  if (status.practicedToday) {
    return status.days == 1
        ? 'Hoy ya practicaste. Llevas 1 día.'
        : 'Hoy ya practicaste. Llevas $days seguidos.';
  }
  return 'Completa la sesión de hoy para llevar la racha a $days.';
}

/// Tira de 7 celdas de 44 de alto: «Últimos 7 días» (hoy es la última) en el
/// Home v2.1. Hoy se rotula «HOY» y, si la meta está pendiente, lleva un
/// borde discontinuo.
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
    final pendingToday =
        day.isToday && day.status != WeekDayStatus.completed;
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

    final cell = Container(
      height: 44,
      decoration: BoxDecoration(
        // Hoy pendiente: superficie de tile con borde discontinuo.
        color: pendingToday && day.status == WeekDayStatus.none
            ? colors.tile
            : bg,
        borderRadius: DesignTokens.borderRadiusCell,
        border: day.isToday && !pendingToday
            ? Border.all(color: colors.brand, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.isToday ? 'HOY' : day.shortLabel,
            style: TextStyle(
              fontSize: day.isToday ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: pendingToday && day.status == WeekDayStatus.none
                  ? colors.brand
                  : fg,
              height: 1.1,
            ),
          ),
          if (icon != null)
            Icon(icon, size: 14, color: fg)
          else
            const SizedBox(height: 14),
        ],
      ),
    );

    return Semantics(
      key: ValueKey('week-day-${day.day.weekday}'),
      label: weekDaySemanticsLabel(day, goal),
      excludeSemantics: true,
      child: pendingToday
          ? CustomPaint(
              key: const ValueKey('week-today-pending'),
              foregroundPainter: _DashedRRectPainter(color: colors.brand),
              child: cell,
            )
          : cell,
    );
  }
}

/// Borde discontinuo de 2 px con el radio de celda.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color});

  final Color color;

  static const double _stroke = 2;
  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = DesignTokens.borderRadiusCell.toRRect(
      (Offset.zero & size).deflate(_stroke / 2),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = color;
    for (final PathMetric metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) => old.color != color;
}
