import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/widgets/count_up_text.dart';
import 'package:togesc/app/app_theme.dart';
import 'package:togesc/models/practice_session_preferences.dart';
import 'package:togesc/providers/today_session_provider.dart';
import 'package:togesc/utils/today_session.dart';
import 'package:togesc/widgets/home_v2/today_session_hero.dart';

const _plan = TodaySessionPlan(
  focusNotes: [
    TodayFocusNote(
      note: 'F',
      accuracyPercent: 40,
      isCritical: false,
      isOverdue: true,
      isLearning: true,
      srsLevel: 1,
      timesSeen: 10,
    ),
    TodayFocusNote(
      note: 'A#',
      accuracyPercent: null,
      isCritical: false,
      isOverdue: false,
      isLearning: true,
      srsLevel: 0,
    ),
  ],
  roundGoal: SessionRoundGoal.twelve,
);

Future<void> _pump(
  WidgetTester tester, {
  bool completedToday = false,
  double? lastAccuracy,
  bool showSteps = true,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TodaySessionHero(
            plan: _plan,
            onStart: () {},
            onAdjust: () {},
            completedToday: completedToday,
            lastAccuracyPercent: lastAccuracy,
            showSteps: showSteps,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('pendiente: «Empezar sesión», punto vivo y pasos', (tester) async {
    await _pump(tester);

    expect(find.text('SESIÓN DE HOY'), findsOneWidget);
    expect(find.text('Empezar sesión'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-live-dot')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-steps')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-done-icon')), findsNothing);
  });

  testWidgets('hecha hoy: lo reconoce y deja de parecer una tarea', (
    tester,
  ) async {
    await _pump(
      tester,
      completedToday: true,
      lastAccuracy: 78.4,
      showSteps: false,
    );
    // La precisión cuenta desde 0 (pulido del lote E).
    await tester.pump(CountUpText.defaultDuration);

    expect(find.text('SESIÓN DE HOY HECHA'), findsOneWidget);
    expect(find.text('78 %'), findsOneWidget);
    expect(find.text('de precisión en tu última sesión'), findsOneWidget);
    expect(
      find.text('Hecho por hoy. Próxima sesión: F y A#.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('today-done-icon')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-live-dot')), findsNothing);
    expect(find.byKey(const ValueKey('today-steps')), findsNothing);

    // La misma clave y una sola acción principal, con otra etiqueta.
    final cta = find.byKey(const ValueKey('today-start-cta'));
    expect(cta, findsOneWidget);
    expect(
      find.descendant(of: cta, matching: find.text('Practicar más')),
      findsOneWidget,
    );
    expect(find.text('Empezar sesión'), findsNothing);
  });

  testWidgets('hecha hoy sin precisión conocida: mantiene las rondas', (
    tester,
  ) async {
    await _pump(tester, completedToday: true);

    expect(find.text('SESIÓN DE HOY HECHA'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('de precisión en tu última sesión'), findsNothing);
  });
}
