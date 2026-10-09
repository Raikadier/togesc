import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/router.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/constants/subscription_constants.dart';
import 'package:togesc/models/engagement_stats.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/models/practice_session_preferences.dart';
import 'package:togesc/providers/clock_provider.dart';
import 'package:togesc/providers/engagement_stats_provider.dart';
import 'package:togesc/providers/practice_focus_provider.dart';
import 'package:togesc/providers/today_session_provider.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/utils/calendar_week.dart';
import 'package:togesc/utils/today_session.dart';
import 'package:togesc/widgets/home_v2/home_app_bar.dart';
import 'package:togesc/widgets/home_v2/home_mode_access.dart';
import 'package:togesc/widgets/home_v2/today_session_hero.dart';

/// Viernes 9 de octubre de 2026, 18:00.
final _now = DateTime(2026, 10, 9, 18);

const _focus = [
  TodayFocusNote(
    note: 'C',
    accuracyPercent: 32,
    isCritical: true,
    isOverdue: true,
    isLearning: false,
    srsLevel: 1,
  ),
  TodayFocusNote(
    note: 'F#',
    accuracyPercent: 61,
    isCritical: false,
    isOverdue: true,
    isLearning: false,
    srsLevel: 2,
  ),
  TodayFocusNote(
    note: 'A',
    accuracyPercent: 70,
    isCritical: false,
    isOverdue: false,
    isLearning: true,
    srsLevel: 2,
  ),
];

final _resume = ResumeSessionInfo(
  kind: PracticeKind.game,
  modeId: GameMode.interval.id,
  label: 'Intervalo (2 notas)',
  route: '/game/${GameMode.interval.id}',
  rounds: 8,
  correctRounds: 6,
  at: _now.subtract(const Duration(hours: 2)),
);

CalendarWeek _week() => buildCalendarWeek(
      [
        PracticeSessionLog(
          modeId: 1,
          kind: PracticeKind.game,
          roundsCompleted: 12,
          correctRounds: 10,
          endedAt: DateTime(2026, 10, 5, 10),
        ),
        PracticeSessionLog(
          modeId: 1,
          kind: PracticeKind.game,
          roundsCompleted: 5,
          correctRounds: 3,
          endedAt: DateTime(2026, 10, 6, 10),
        ),
        PracticeSessionLog(
          modeId: 2,
          kind: PracticeKind.game,
          roundsCompleted: 12,
          correctRounds: 9,
          endedAt: DateTime(2026, 10, 8, 10),
        ),
      ],
      now: _now,
      dailyGoalRounds: 12,
    );

const _engagement = EngagementStats(
  currentStreakDays: 5,
  totalXp: 0,
  xpTowardNextMilestone: 0,
  modeMastery: [
    ModeMasteryStats(
      mode: GameMode.singleNote,
      sessionsCount: 24,
      totalRounds: 100,
      correctRounds: 86,
    ),
  ],
);

GoRouter _router() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '${AppRoutes.game}/:modeId',
        builder: (_, state) =>
            Scaffold(body: Text('GAME ${state.pathParameters['modeId']}')),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const Scaffold(body: Text('SETTINGS')),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (_, _) => const Scaffold(body: Text('ACCOUNT')),
      ),
      GoRoute(
        path: AppRoutes.speedSelect,
        builder: (_, _) => const Scaffold(body: Text('SPEED')),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, state) => Scaffold(
          body: Text('PAYWALL ${state.uri.queryParameters['feature']}'),
        ),
      ),
    ],
  );
}

Widget _app({
  List<TodayFocusNote> focus = _focus,
  ResumeSessionInfo? resume,
  bool proLocked = false,
}) {
  return ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      todaySessionPlanProvider.overrideWithValue(
        TodaySessionPlan(focusNotes: focus, roundGoal: SessionRoundGoal.twelve),
      ),
      resumeSessionProvider.overrideWithValue(resume),
      calendarWeekProvider.overrideWithValue(_week()),
      engagementStatsProvider.overrideWithValue(_engagement),
      homeModeAccessProvider.overrideWithValue(
        proLocked ? SubscriptionConstants.isModeFree : (_) => true,
      ),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({onboardingCompleteKey: true});
  });

  group('HomeScreen v2', () {
    testWidgets('hero con datos: rondas, estimación, foco y copy real',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('VIERNES 9 DE OCTUBRE'), findsOneWidget);
      expect(find.text('SESIÓN DE HOY'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('rondas · ≈ 6 min (estimado)'), findsOneWidget);
      expect(
        find.text('El SRS priorizó las tres notas atrasadas o con menor '
            'precisión.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('focus-note-C')), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-note-F#')), findsOneWidget);
      expect(find.byKey(const ValueKey('focus-note-A')), findsOneWidget);
      expect(find.text('32%'), findsOneWidget);
      expect(find.text('61%'), findsOneWidget);
      expect(find.text('Empezar sesión'), findsOneWidget);
      expect(find.text('Ajustar enfoque y duración'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-streak-chip')), findsOneWidget);
    });

    testWidgets('estado vacío: usuario nuevo sin datos', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(focus: const []));
      await tester.pumpAndSettle();

      expect(
        find.text('Tu primera sesión le dará al SRS los datos para elegir '
            'tu foco.'),
        findsOneWidget,
      );
      expect(find.byType(FocusNoteMiniCard), findsNothing);
      expect(find.text('Empezar sesión'), findsOneWidget);
    });

    testWidgets('estado vacío: menos de 3 notas vistas', (tester) async {
      _phone(tester);
      final focus = [
        _focus.first,
        const TodayFocusNote(
          note: 'D',
          accuracyPercent: null,
          isCritical: false,
          isOverdue: false,
          isLearning: false,
          srsLevel: 0,
        ),
        const TodayFocusNote(
          note: 'E',
          accuracyPercent: null,
          isCritical: false,
          isOverdue: false,
          isLearning: false,
          srsLevel: 0,
        ),
      ];
      await tester.pumpWidget(_app(focus: focus));
      await tester.pumpAndSettle();

      expect(
        find.text('El SRS solo tiene datos de 1 nota; el resto del foco son '
            'notas nuevas.'),
        findsOneWidget,
      );
      expect(find.text('Nueva'), findsNWidgets(2));
      expect(find.text('32%'), findsOneWidget);
    });

    testWidgets('Retomar oculto sin sesión previa', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home-resume-row')), findsNothing);
      expect(find.textContaining('Retomar'), findsNothing);
    });

    testWidgets('Retomar visible con sesión previa y navega al modo',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(resume: _resume));
      await tester.pumpAndSettle();

      expect(find.text('Retomar «Intervalo (2 notas)»'), findsOneWidget);
      expect(find.text('8 rondas · hace 2 h'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home-resume-row')));
      await tester.pumpAndSettle();
      expect(find.text('GAME ${GameMode.interval.id}'), findsOneWidget);
    });

    testWidgets('CTA entra en la sesión con el pool de foco', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('today-start-cta')));
      await tester.pumpAndSettle();

      expect(find.text('GAME ${GameMode.singleNote.id}'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.text('GAME ${GameMode.singleNote.id}')),
      );
      expect(container.read(practiceFocusNotesProvider), ['C', 'F#', 'A']);
      expect(container.read(practiceFocusNoteProvider), isNull);
    });

    testWidgets('Ajustar enfoque lleva a la configuración', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('today-adjust-link')));
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('práctica libre: progreso real y candado Pro al paywall',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(proLocked: true));
      await tester.pumpAndSettle();

      expect(find.text('Práctica libre'), findsOneWidget);
      expect(find.text('86% · 24 ses.'), findsOneWidget);
      expect(find.text('Sin sesiones'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('free-tile-chord')),
          matching: find.byKey(const ValueKey('pro-lock-icon')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('free-tile-singleNote')),
          matching: find.text('PRO'),
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('free-tile-chord')));
      await tester.pumpAndSettle();
      expect(find.text('PAYWALL Acordes'), findsOneWidget);
    });

    testWidgets('Pro sin candado si el usuario tiene acceso', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pro-lock-icon')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('free-tile-chord')));
      await tester.pumpAndSettle();
      expect(find.text('GAME ${GameMode.chord.id}'), findsOneWidget);
    });

    testWidgets('Ver todos abre el catálogo completo de modos',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(proLocked: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-see-all-modes')));
      await tester.pumpAndSettle();

      expect(find.text('Todos los modos'), findsOneWidget);
      expect(find.text('Aleatorio'), findsOneWidget);
      expect(find.text('Solo sostenidos'), findsOneWidget);
      expect(find.text('Velocidad'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('all-modes-random')));
      await tester.pumpAndSettle();
      expect(find.text('PAYWALL Modo aleatorio'), findsOneWidget);
    });

    testWidgets('semana L–D con Semantics por día', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Esta semana · 3 de 7 días'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Lunes: meta cumplida, 12 de 12 rondas'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Martes: práctica parcial, 5 de 12 rondas'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Miércoles: sin practicar'), findsOneWidget);
      expect(find.bySemanticsLabel('Viernes, hoy: sin práctica'),
          findsOneWidget);
      expect(find.bySemanticsLabel('Domingo: día futuro'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('web ancho: contenido centrado con ancho máximo y app bar',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(resume: _resume));
      await tester.pumpAndSettle();

      final hero = find.byKey(const ValueKey('today-session-hero'));
      final rect = tester.getRect(hero);
      expect(rect.width, lessThanOrEqualTo(homeContentMaxWidth));
      expect(rect.center.dx, closeTo(640, 1));
      expect(find.byType(HomeAppBar), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home-avatar')));
      await tester.pumpAndSettle();
      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets('móvil: sin app bar propia (la pone el shell)', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.byType(HomeAppBar), findsNothing);
    });
  });
}
