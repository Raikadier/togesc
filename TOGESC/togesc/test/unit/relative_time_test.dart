import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/utils/relative_time.dart';

void main() {
  final now = DateTime(2026, 10, 9, 18, 30);

  String rel(DateTime then) => formatRelativeTimeEs(then, now: now);

  group('formatRelativeTimeEs', () {
    test('segundos', () {
      expect(rel(now), 'hace un momento');
      expect(rel(now.subtract(const Duration(seconds: 59))), 'hace un momento');
    });

    test('minutos', () {
      expect(rel(now.subtract(const Duration(minutes: 1))), 'hace 1 min');
      expect(rel(now.subtract(const Duration(minutes: 59))), 'hace 59 min');
    });

    test('horas', () {
      expect(rel(now.subtract(const Duration(hours: 2))), 'hace 2 h');
      expect(
        rel(now.subtract(const Duration(hours: 23, minutes: 59))),
        'hace 23 h',
      );
    });

    test('ayer y dias', () {
      expect(rel(DateTime(2026, 10, 8, 10)), 'ayer');
      expect(rel(DateTime(2026, 10, 7, 20)), 'hace 2 días');
      expect(rel(DateTime(2026, 10, 3, 9)), 'hace 6 días');
    });

    test('semanas', () {
      expect(rel(DateTime(2026, 10, 2, 9)), 'hace 1 semana');
      expect(rel(DateTime(2026, 9, 18, 9)), 'hace 3 semanas');
    });

    test('meses y anos', () {
      expect(rel(DateTime(2026, 9, 1)), 'hace 1 mes');
      expect(rel(DateTime(2026, 6, 1)), 'hace 4 meses');
      expect(rel(DateTime(2025, 9, 1)), 'hace más de un año');
    });

    test('fecha futura', () {
      expect(rel(now.add(const Duration(minutes: 5))), 'ahora mismo');
    });
  });

  group('formatLongDateEs', () {
    test('overline del Home', () {
      expect(formatLongDateEs(DateTime(2026, 9, 10)), 'Jueves 10 de septiembre');
      expect(formatLongDateEs(DateTime(2026, 10, 9)), 'Viernes 9 de octubre');
      expect(formatLongDateEs(DateTime(2026, 10, 11)), 'Domingo 11 de octubre');
    });

    test('weekdayLongLabelEs', () {
      expect(weekdayLongLabelEs(DateTime(2026, 10, 7)), 'Miércoles');
      expect(weekdayLongLabelEs(DateTime(2026, 10, 10)), 'Sábado');
    });
  });
}
