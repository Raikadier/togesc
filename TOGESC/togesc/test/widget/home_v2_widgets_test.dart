import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/engagement_stats.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/providers/today_session_provider.dart';
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

    test('el copy se ajusta al número de notas foco', () {
      expect(
        todayHeroCopy([_note('C', 40, overdue: true)]),
        'El SRS priorizó la nota atrasada o con menor precisión.',
      );
      expect(
        todayHeroCopy([_note('C', 40), _note('D', 50)]),
        'El SRS priorizó las dos notas con menor precisión.',
      );
      expect(
        todayHeroCopy([
          _note('C', 40),
          _note('D', 50),
          _note('E', 60),
          _note('F', 70),
        ]),
        'El SRS priorizó las cuatro notas con menor precisión.',
      );
    });

    test('foco elegido a mano', () {
      expect(
        todayHeroCopy([_note('C', 40)], custom: true),
        'Elegiste una nota foco para hoy; el resto sigue el repaso SRS '
        'normal.',
      );
      expect(
        todayHeroCopy([_note('C', 40), _note('D', null)], custom: true),
        'Elegiste dos notas foco para hoy; el resto sigue el repaso SRS '
        'normal.',
      );
    });

    test('estado escrito de la mini-card', () {
      expect(focusNoteStateLabel(_note('C', null)), 'Nueva');
      expect(focusNoteStateLabel(_note('C', 49.9)), 'Crítica');
      expect(focusNoteStateLabel(_note('C', 50)), 'En curso');
      expect(focusNoteStateLabel(_note('C', 75)), 'Consolidada');
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
      final week = buildRecentDays(
        const [],
        now: DateTime(2026, 10, 9, 18),
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WeekStrip(week: week))),
      );
      // Sábado 3 → viernes 9: hoy (viernes) se rotula «HOY».
      for (final label in ['S', 'D', 'L', 'M', 'X', 'J', 'HOY']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('V'), findsNothing);
      expect(find.byKey(const ValueKey('week-today-pending')), findsOneWidget);
      // Sin historial: ningún día cumplido ni fallado, sin iconos de estado.
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('hoy con la meta cumplida no lleva borde discontinuo',
        (tester) async {
      final now = DateTime(2026, 10, 9, 18);
      final week = buildRecentDays(
        [
          PracticeSessionLog(
            modeId: 1,
            kind: PracticeKind.game,
            roundsCompleted: 12,
            correctRounds: 10,
            endedAt: DateTime(2026, 10, 9, 10),
          ),
        ],
        now: now,
        dailyGoalRounds: 12,
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WeekStrip(week: week))),
      );
      expect(find.byKey(const ValueKey('week-today-pending')), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    test('buildRecentDays: de hace 6 días a hoy', () {
      final week = buildRecentDays(const [], now: DateTime(2026, 10, 9, 18));
      expect(week.days.first.day, DateTime(2026, 10, 3));
      expect(week.days.last.day, DateTime(2026, 10, 9));
      expect(week.days.last.isToday, isTrue);
      expect(week.days.where((d) => d.isFuture), isEmpty);
    });

    test('weekStreakCopy', () {
      expect(
        weekStreakCopy(
          const HomeStreakStatus(practicedToday: false, days: 1),
        ),
        'Completa la sesión de hoy para llevar la racha a 1 día.',
      );
      expect(
        weekStreakCopy(
          const HomeStreakStatus(practicedToday: false, days: 6),
        ),
        'Completa la sesión de hoy para llevar la racha a 6 días.',
      );
      expect(
        weekStreakCopy(const HomeStreakStatus(practicedToday: true, days: 1)),
        'Hoy ya practicaste. Llevas 1 día.',
      );
      expect(
        weekStreakCopy(const HomeStreakStatus(practicedToday: true, days: 5)),
        'Hoy ya practicaste. Llevas 5 días seguidos.',
      );
    });

    group('HomeStreakStatus.fromHistory', () {
      final now = DateTime(2026, 10, 9, 18);
      PracticeSessionLog on(int day) => PracticeSessionLog(
            modeId: 1,
            kind: PracticeKind.game,
            roundsCompleted: 5,
            correctRounds: 3,
            endedAt: DateTime(2026, 10, day, 10),
          );

      test('sin historial: la racha llegaría a 1', () {
        final s = HomeStreakStatus.fromHistory(const [], now: now);
        expect(s.practicedToday, isFalse);
        expect(s.days, 1);
      });

      test('ayer y anteayer sin hoy: llegaría a 3', () {
        final s = HomeStreakStatus.fromHistory([on(8), on(7)], now: now);
        expect(s.practicedToday, isFalse);
        expect(s.days, 3);
      });

      test('hoy, ayer y anteayer: lleva 3', () {
        final s = HomeStreakStatus.fromHistory([on(9), on(8), on(7)], now: now);
        expect(s.practicedToday, isTrue);
        expect(s.days, 3);
      });

      test('un hueco corta la racha', () {
        final s = HomeStreakStatus.fromHistory([on(9), on(7)], now: now);
        expect(s.days, 1);
      });
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
