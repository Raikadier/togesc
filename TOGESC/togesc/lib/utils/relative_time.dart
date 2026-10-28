/// Formateadores de fechas en español sin depender del locale de `intl`
/// (no se inicializa `initializeDateFormatting` en la app).
library;

/// Tiempo relativo en español: «hace un momento», «hace 5 min», «hace 2 h»,
/// «ayer», «hace 3 días», «hace 1 semana», «hace 2 meses», «hace más de un
/// año». [now] se inyecta siempre para ser determinista.
///
/// Fechas futuras (reloj desajustado) devuelven «ahora mismo».
String formatRelativeTimeEs(DateTime then, {required DateTime now}) {
  final diff = now.difference(then);
  if (diff.isNegative || diff.inSeconds < 60) {
    return diff.isNegative ? 'ahora mismo' : 'hace un momento';
  }
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';

  final localNow = now.toLocal();
  final localThen = then.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final thenDay = DateTime(localThen.year, localThen.month, localThen.day);
  // Días de calendario; se redondea para absorber cambios de horario (DST).
  final calendarDays = (today.difference(thenDay).inHours / 24).round();

  if (calendarDays <= 1) return 'ayer';
  if (calendarDays < 7) return 'hace $calendarDays días';
  if (calendarDays < 30) {
    final weeks = calendarDays ~/ 7;
    return weeks == 1 ? 'hace 1 semana' : 'hace $weeks semanas';
  }
  if (calendarDays < 365) {
    final months = calendarDays ~/ 30;
    return months == 1 ? 'hace 1 mes' : 'hace $months meses';
  }
  return 'hace más de un año';
}

const List<String> _weekdaysEs = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<String> _monthsEs = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Nombre del día de la semana en español, con mayúscula inicial («Jueves»).
String weekdayLongLabelEs(DateTime day) => _weekdaysEs[day.weekday - 1];

/// Fecha larga para la overline del Home: «Jueves 10 de septiembre».
String formatLongDateEs(DateTime day) {
  return '${weekdayLongLabelEs(day)} ${day.day} de ${_monthsEs[day.month - 1]}';
}
