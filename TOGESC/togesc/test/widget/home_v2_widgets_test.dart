import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/engagement_stats.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/utils/calendar_week.dart';
import 'package:togesc/utils/today_session.dart';
import 'package:togesc/widgets/home_v2/free_practice_tiles.dart';
import 'package:togesc/widgets/home_v2/resume_row.dart';
import 'package:togesc/widgets/home_v2/today_session_hero.dart';
import 'package:togesc/widgets/home_v2/week_strip.dart';

TodayFocusNote _note(
  String note,
  double? pct, {
  bool critical = false,
  bool overdue = false,
  bool learning = false,
}) =>
    TodayFocusNote(
      note: note,
      accuracyPercent: pct,
      isCritical: critical,
      isOverdue: overdue,
      isLearning: learning,
      srsLevel: 0,
    );

void main() {
  group('todayHeroCopy (D10, solo datos reales)', () {
    test('sin foco: primera sesión', () {
      expect(todayHeroCopy(const []), startsWith('Tu primera sesión'));
    });

    test('ninguna nota vista: usuario nuevo', () {
      expect(
        todayHeroCopy([_note('C', null), _note('D', null), _note('E', null)]),
        startsWith('Aún no hay datos de precisión'),
      );
    });

    test('dos de tres vistas', () {
      expect(
        todayHeroCopy([_note('C', 40), _note('D', 55), _note('E', null)]),
        'El SRS solo tiene datos de 2 notas; el resto del foco son notas '
        'nuevas.',
      );
    });

    test('atrasadas, en aprendizaje o solo menor precisión', () {
      expect(
        todayHeroCopy([
          _note('C', 40, overdue: true),
          _note('D', 50),
          _note('E', 60),
        ]),
        'El SRS priorizó las tres notas atrasadas o con menor precisión.',
      );
      expect(
        todayHeroCopy([
          _note('C', 40, learning: true),
          _note('D', 50),
          _note('E', 60),
        ]),
        'El SRS priorizó las tres notas en aprendizaje o con menor precisión.',
      );
      expect(
        todayHeroCopy([_note('C', 40), _note('D', 50), _note('E', 60)]),
        'El SRS priorizó las tres notas con menor precisión.',
      );
    });
  });

  group('resumeDetailText', () {
    final now = DateTime(2026, 10, 9, 18);
    ResumeSessionInfo info(int? rounds) => ResumeSessionInfo(
          kind: PracticeKind.game,
          modeId: 1,
          label: 'Una sola nota',
          route: '/game/1',
          rounds: rounds,
          correctRounds: null,
          at: now.subtract(const Duration(hours: 2)),
        );

    test('con rondas', () {
      expect(resumeDetailText(info(8), now), '8 rondas · hace 2 h');
      expect(resumeDetailText(info(1), now), '1 ronda · hace 2 h');
    });

    test('sin rondas registradas solo muestra la hora', () {
      expect(resumeDetailText(info(null), now), 'hace 2 h');
    });
  });

  group('HomeModeEntry', () {
    HomeModeEntry entry({ModeMasteryStats? mastery, bool locked = false}) =>
        HomeModeEntry(
          mode: GameMode.chord,
          title: 'Acorde',
          subtitle: '',
          icon: Icons.piano_rounded,
          isPro: true,
          locked: locked,
          mastery: mastery,
          onTap: () {},
        );

    test('etiqueta de progreso real', () {
      expect(entry().progressLabel, 'Sin sesiones');
      expect(
        entry(
          mastery: const ModeMasteryStats(
            mode: GameMode.chord,
            sessionsCount: 24,
            totalRounds: 50,
            correctRounds: 43,
          ),
        ).progressLabel,
        '86% · 24 ses.',
      );
    });

    testWidgets('tile bloqueado: PRO con candado y Semantics', (tester) async {
      var taps = 0;
      final e = HomeModeEntry(
        mode: GameMode.chord,
        title: 'Acorde',
        subtitle: '',
        icon: Icons.piano_rounded,
        isPro: true,
        locked: true,
        mastery: null,
        onTap: () => taps++,
      );
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FreePracticeTiles(entries: [e])),
        ),
      );
      expect(find.text('PRO'), findsOneWidget);
      expect(find.byKey(const ValueKey('pro-lock-icon')), findsOneWidget);
      expect(
        find.bySemanticsLabel('Acorde, sin sesiones, requiere Pro'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('free-tile-chord')));
      expect(taps, 1);
      handle.dispose();
    });
  });

  group('WeekStrip', () {
    testWidgets('cada día lleva icono además del color', (tester) async {
      final week = buildCalendarWeek(
        const [],
        now: DateTime(2026, 10, 9, 18),
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WeekStrip(week: week))),
      );
      for (final label in ['L', 'M', 'X', 'J', 'V', 'S', 'D']) {
        expect(find.text(label), findsOneWidget);
      }
      // Sin historial: ningún día cumplido ni fallado, sin iconos de estado.
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    test('etiqueta semántica por estado', () {
      final day = CalendarWeekDay(
        day: DateTime(2026, 10, 7),
        sessions: 1,
        rounds: 4,
        correct: 3,
        status: WeekDayStatus.partial,
        isToday: true,
        isFuture: false,
      );
      expect(
        weekDaySemanticsLabel(day, 12),
        'Miércoles, hoy: práctica parcial, 4 de 12 rondas',
      );
    });
  });
}
