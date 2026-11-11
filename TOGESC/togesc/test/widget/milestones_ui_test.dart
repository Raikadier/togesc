import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togesc/app/app_theme.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/providers/app_preferences_provider.dart';
import 'package:togesc/providers/session_history_provider.dart';
import 'package:togesc/utils/milestones.dart';
import 'package:togesc/widgets/home_v2/home_app_bar.dart';
import 'package:togesc/widgets/profile_views.dart';
import 'package:togesc/widgets/session_v2/session_summary_view.dart';
import 'package:togesc/widgets/session_v2/session_top_bar.dart';

final _at = DateTime(2026, 11, 11, 18);

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void _bigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('resumen: píldoras de hitos y «N/12» si cambia', (tester) async {
    _bigView(tester);
    final summaries = [
      for (final n in chromaticNotes)
        NoteProgressSummary(
          note: n,
          isLearning: false,
          consecutiveCorrect: 0,
          timesSeen: n == 'C' ? 10 : 0,
          timesCorrect: n == 'C' ? 9 : 0,
          weight: 1,
          isOverdue: false,
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SessionSummaryView(
            rounds: 10,
            correctRounds: 9,
            meanResponseTimeSec: null,
            changes: const [],
            summaries: summaries,
            onHome: () {},
            onProgress: () {},
            consolidatedBefore: 0,
            milestones: [
              Milestone(
                kind: MilestoneKind.noteConsolidated,
                at: _at,
                note: 'C',
              ),
              Milestone(kind: MilestoneKind.bestSession, at: _at, value: 90),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('session-summary-milestones')),
      findsOneWidget,
    );
    expect(find.text('C, consolidada'), findsOneWidget);
    expect(find.text('Tu mejor sesión hasta hoy'), findsOneWidget);
    expect(find.text('1/12'), findsOneWidget);
    expect(find.text('consolidadas'), findsOneWidget);
  });

  testWidgets('resumen sin hitos: ni píldoras ni «N/12»', (tester) async {
    _bigView(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SessionSummaryView(
            rounds: 10,
            correctRounds: 5,
            meanResponseTimeSec: null,
            changes: const [],
            summaries: const [],
            onHome: () {},
            onProgress: () {},
            consolidatedBefore: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('session-summary-milestones')),
      findsNothing,
    );
    expect(find.text('0/12'), findsNothing);
  });

  testWidgets('chip ⚡ solo desde 2 seguidas, con «N seguidas»', (tester) async {
    Future<void> pump(int streak) => tester.pumpWidget(
      _app(
        SessionStatChips(
          stats: SessionStats(
            round: 3,
            targetRounds: 12,
            accuracyPercent: 50,
            streak: streak,
          ),
        ),
      ),
    );

    await pump(1);
    expect(find.byKey(const ValueKey('session-chip-streak')), findsNothing);

    await pump(3);
    expect(find.byKey(const ValueKey('session-chip-streak')), findsOneWidget);
    expect(find.byTooltip('3 seguidas'), findsOneWidget);
    expect(find.bySemanticsLabel('3 seguidas'), findsWidgets);
  });

  testWidgets('chip de racha del Home: «Récord» solo el día del récord', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const StreakChip(streakDays: 5)));
    expect(find.text('Récord'), findsNothing);

    await tester.pumpWidget(
      _app(const StreakChip(streakDays: 5, isRecord: true)),
    );
    expect(find.text('Récord'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Racha de práctica: 5 días, récord'),
      findsOneWidget,
    );
  });

  group('Perfil, «Tus hitos»', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pump(WidgetTester tester, List<Milestone> log) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [milestoneLogProvider.overrideWithValue(log)],
            child: _app(const ProfileMilestones()),
          ),
        );

    testWidgets('sin hitos el bloque no aparece', (tester) async {
      await pump(tester, const []);
      expect(find.text('Tus hitos'), findsNothing);
    });

    testWidgets('lista los hitos con fecha, el más reciente primero', (
      tester,
    ) async {
      await pump(tester, [
        Milestone(
          kind: MilestoneKind.streakRecord,
          at: DateTime(2026, 11, 9, 10),
          value: 3,
        ),
        Milestone(kind: MilestoneKind.octaveComplete, at: _at),
      ]);
      await tester.pump();
      expect(find.text('Tus hitos'), findsOneWidget);
      expect(find.text('Racha récord: 3 días'), findsOneWidget);
      expect(find.text('11 de noviembre de 2026'), findsOneWidget);
      final first = tester.getTopLeft(find.text('Octava completa')).dy;
      final second = tester.getTopLeft(find.text('Racha récord: 3 días')).dy;
      expect(first, lessThan(second));
    });
  });

  test('record() guarda récords y el hito de racha récord', () async {
    final day = DateTime(2026, 11, 11, 10);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final prefs = await container.read(appPreferencesProvider.future);
    await container.read(sessionHistoryProvider.future);
    final notifier = container.read(sessionHistoryProvider.notifier);
    final mode = GameMode.values.first;

    Future<void> play(
      DateTime at,
      int correct, [
      List<Milestone> ms = const [],
    ]) => notifier.record(
      mode: mode,
      kind: PracticeKind.game,
      roundsCompleted: 10,
      correctRounds: correct,
      endedAt: at,
      sessionMilestones: ms,
    );

    await play(day.subtract(const Duration(days: 1)), 6);
    expect(prefs.bestSessionAccuracy(mode.id), 60);
    expect(prefs.milestones, isEmpty, reason: '1 día no es récord');

    final consolidated = Milestone(
      kind: MilestoneKind.noteConsolidated,
      at: day,
      note: 'C',
    );
    await play(day, 8, [consolidated]);
    expect(prefs.bestSessionAccuracy(mode.id), 80);
    expect(prefs.bestStreakDays, 2);
    expect(prefs.milestones.map((m) => m.kind), [
      MilestoneKind.noteConsolidated,
      MilestoneKind.streakRecord,
    ]);
    expect(container.read(milestoneLogProvider), hasLength(2));

    // Otra sesión el mismo día: ni récord nuevo ni hito repetido.
    await play(day.add(const Duration(hours: 2)), 5);
    expect(prefs.bestSessionAccuracy(mode.id), 80);
    expect(prefs.milestones, hasLength(2));
  });
}
