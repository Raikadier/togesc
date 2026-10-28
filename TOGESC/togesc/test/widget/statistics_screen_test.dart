import 'dart:math';
import 'dart:ui' as ui show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/constants/notes.dart';
import 'package:togesc/models/last_practice_session.dart';
import 'package:togesc/models/note_data.dart';
import 'package:togesc/models/practice_session_log.dart';
import 'package:togesc/providers/clock_provider.dart';
import 'package:togesc/providers/session_history_provider.dart';
import 'package:togesc/providers/srs_provider.dart';
import 'package:togesc/screens/statistics_screen.dart';
import 'package:togesc/services/progress_repository.dart';
import 'package:togesc/services/srs_system.dart';
import 'package:togesc/widgets/progress_v2/progress_access.dart';

final _now = DateTime(2026, 10, 9, 12);

void main() {
  late SRSSystem srs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    srs = SRSSystem(
      repository: InMemoryProgressRepository(),
      random: Random(42),
      clock: () => _now,
    );
    await srs.loadProgress();
  });

  /// Fija vistas/aciertos de una nota (solo campos que lee la rejilla).
  void seed(String note, {required int seen, required int correct}) {
    final NoteData data = srs.noteData[note]!;
    data.timesSeen = seen;
    data.timesCorrect = correct;
    // Sin `nextReview` el SRS la da por vencida; por defecto, al día.
    data.nextReview = _now.add(const Duration(days: 1)).toIso8601String();
  }

  Widget buildApp({
    bool pro = true,
    List<PracticeSessionLog> history = const [],
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.statistics,
      routes: [
        GoRoute(
          path: AppRoutes.statistics,
          builder: (_, _) => const StatisticsScreen(),
        ),
        GoRoute(
          path: AppRoutes.paywall,
          builder: (_, _) => const Scaffold(body: Text('PAYWALL')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '${AppRoutes.game}/:modeId',
          builder: (_, state) =>
              Scaffold(body: Text('GAME ${state.pathParameters['modeId']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(),
        ),
        srsSystemProvider.overrideWith(() => _FakeSRSNotifier(srs)),
        sessionHistoryProvider.overrideWith(
          () => _FakeSessionHistoryNotifier(history),
        ),
        clockProvider.overrideWithValue(() => _now),
        progressProAccessProvider.overrideWithValue(pro),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool pro = true,
    List<PracticeSessionLog> history = const [],
    bool grid = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(420, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp(pro: pro, history: history));
    await tester.pumpAndSettle();
    // En móvil la card de dominio abre en «Rueda» (v2.1); los tests de la
    // rejilla cambian a «Rejilla».
    if (grid) {
      await tester.tap(find.text('Rejilla'));
      await tester.pumpAndSettle();
    }
  }

  PracticeSessionLog log(int daysAgo, {int rounds = 10, int correct = 8}) {
    return PracticeSessionLog(
      modeId: GameMode.singleNote.id,
      kind: PracticeKind.game,
      roundsCompleted: rounds,
      correctRounds: correct,
      endedAt: _now.subtract(Duration(days: daysAgo, hours: 1)),
    );
  }

  /// «—» dentro de las celdas de la rejilla (el KPI de latencia también
  /// puede mostrar «—»).
  Finder emptyCells() => find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('mastery-cell-'),
        ),
        matching: find.text('—'),
      );

  Color cellColor(WidgetTester tester, String note) {
    final material = tester.widget<Material>(
      find.byKey(ValueKey('mastery-cell-$note')),
    );
    return material.color!;
  }

  testWidgets('rejilla de 12 celdas con colores por umbral', (tester) async {
    seed('C', seen: 10, correct: 4); // 40 % → rojo
    seed('D', seen: 10, correct: 6); // 60 % → ámbar
    seed('E', seen: 10, correct: 9); // 90 % → verde
    await pumpScreen(tester, history: [log(0)]);

    for (final note in notes.keys) {
      expect(find.byKey(ValueKey('mastery-cell-$note')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('mastery-cell-C')), findsOneWidget);

    expect(cellColor(tester, 'C'), DesignTokens.masteryRed);
    expect(cellColor(tester, 'D'), DesignTokens.masteryAmber);
    expect(
      DesignTokens.masteryGreenScale,
      contains(cellColor(tester, 'E')),
    );
    expect(cellColor(tester, 'F'), DesignTokens.masteryEmpty);

    expect(find.text('40%'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    // 9 notas nunca vistas muestran «—».
    expect(emptyCells(), findsNWidgets(9));
    expect(find.byKey(const Key('progress-mastery-legend')), findsOneWidget);
    expect(find.textContaining('consolidadas · '), findsOneWidget);
  });

  testWidgets('cada celda tiene Semantics de lectura completa', (
    tester,
  ) async {
    seed('A#', seen: 50, correct: 21); // 42 %
    await pumpScreen(tester, history: [log(0)]);

    expect(
      find.bySemanticsLabel(RegExp(r'^A sostenido, 42 %, crítica, nivel \d de 5$')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('C, sin datos todavía'),
      findsOneWidget,
    );
  });

  testWidgets('estado vacío para un usuario nuevo', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('progress-empty-state')), findsOneWidget);
    expect(find.text('Aún no hay progreso'), findsOneWidget);
    expect(find.byKey(const Key('progress-global-accuracy')), findsNothing);
    // La rejilla se ve igualmente, con las 12 notas sin datos.
    expect(emptyCells(), findsNWidgets(12));
  });

  testWidgets('delta oculto sin datos de la semana pasada', (tester) async {
    seed('C', seen: 10, correct: 7);
    await pumpScreen(tester, history: [log(1)]);

    expect(find.byKey(const Key('progress-global-accuracy')), findsOneWidget);
    expect(find.byKey(const Key('progress-weekly-delta')), findsNothing);
    expect(find.textContaining('vs. semana pasada'), findsNothing);
    expect(find.text('78% de la meta (90%)'), findsOneWidget);
  });

  testWidgets('delta visible y rotulado por rondas con dos semanas', (
    tester,
  ) async {
    seed('C', seen: 10, correct: 7);
    await pumpScreen(
      tester,
      history: [log(1, correct: 9), log(9, correct: 6)],
    );

    expect(find.byKey(const Key('progress-weekly-delta')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Precisión de rondas: +30.0 pts vs. semana pasada',
      ),
      findsOneWidget,
    );
  });

  testWidgets('usuario gratis ve la rejilla y candado en el historial Pro', (
    tester,
  ) async {
    seed('C', seen: 10, correct: 9);
    await pumpScreen(
      tester,
      pro: false,
      history: [log(0), log(1), log(2), log(3)],
    );

    for (final note in notes.keys) {
      expect(find.byKey(ValueKey('mastery-cell-$note')), findsOneWidget);
    }
    expect(find.text('Últimas sesiones'), findsOneWidget);
    expect(find.text('10 rondas · 8 aciertos'), findsNWidgets(3));

    final historyButton = find.byKey(const Key('progress-history-button'));
    expect(
      find.descendant(
        of: historyButton,
        matching: find.byIcon(Icons.lock_rounded),
      ),
      findsOneWidget,
    );
    // La invitación a Pro vive en la pestaña Historial (v2.1).
    expect(find.text('Evolución e historial · Pro'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('progress-tab-history')));
    await tester.pumpAndSettle();
    expect(find.text('Evolución e historial · Pro'), findsOneWidget);
    expect(find.byKey(const Key('progress-history-chart')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('progress-tab-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejilla'));
    await tester.pumpAndSettle();

    await tester.tap(historyButton);
    await tester.pumpAndSettle();
    expect(find.text('PAYWALL'), findsOneWidget);
  });

  testWidgets('usuario Pro abre el historial completo sin candado', (
    tester,
  ) async {
    seed('C', seen: 10, correct: 9);
    await pumpScreen(tester, history: [log(0), log(1), log(2), log(3)]);

    final historyButton = find.byKey(const Key('progress-history-button'));
    expect(
      find.descendant(
        of: historyButton,
        matching: find.byIcon(Icons.lock_rounded),
      ),
      findsNothing,
    );
    expect(find.text('Exportar progreso (CSV)'), findsNothing);

    // «Historial» cambia a la pestaña Historial (no abre otra página).
    await tester.tap(historyButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-panel-history')), findsOneWidget);
    expect(find.byKey(const Key('progress-history-chart')), findsOneWidget);
    expect(find.text('Exportar progreso (CSV)'), findsOneWidget);
    expect(find.text('4 sesiones'), findsOneWidget);
  });

  testWidgets('tocar una celda abre el detalle de la nota', (tester) async {
    seed('G', seen: 8, correct: 6);
    await pumpScreen(tester, history: [log(0)]);

    await tester.tap(find.byKey(const ValueKey('mastery-cell-G')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('note-detail-sheet')), findsOneWidget);
    expect(find.text('Practicar esta nota'), findsOneWidget);
    expect(find.text('Escuchar'), findsOneWidget);
  });

  testWidgets('pestañas Resumen | Historial con semántica y flechas', (
    tester,
  ) async {
    seed('C', seen: 10, correct: 9);
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, history: [log(0), log(1)], grid: false);

    expect(find.byKey(const ValueKey('progress-panel-summary')), findsOneWidget);
    final summaryTab = tester
        .getSemantics(find.byKey(const ValueKey('progress-tab-summary')))
        .getSemanticsData();
    expect(summaryTab.flagsCollection.isSelected, ui.Tristate.isTrue);

    await tester.tap(find.byKey(const ValueKey('progress-tab-summary')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-panel-history')), findsOneWidget);
    expect(find.byKey(const Key('progress-history-chart')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Precisión por sesión, de la más antigua')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-panel-summary')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('móvil: rueda por defecto y selector Rueda / Rejilla', (
    tester,
  ) async {
    seed('C', seen: 10, correct: 9);
    seed('D', seen: 10, correct: 8);
    await pumpScreen(tester, history: [log(0)], grid: false);

    expect(find.byKey(const ValueKey('ear-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('mastery-cell-C')), findsNothing);
    expect(find.text('2/12'), findsOneWidget);
    expect(find.text('consolidadas'), findsOneWidget);

    await tester.tap(find.text('Rejilla'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ear-map')), findsNothing);
    expect(find.byKey(const ValueKey('mastery-cell-C')), findsOneWidget);
  });

  testWidgets('escritorio: rueda y rejilla lado a lado, sin selector', (
    tester,
  ) async {
    seed('C', seen: 10, correct: 9);
    await tester.binding.setSurfaceSize(const Size(1280, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp(history: [log(0)]));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ear-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('mastery-cell-C')), findsOneWidget);
    expect(find.byKey(const Key('progress-mastery-view')), findsNothing);
  });

  testWidgets('celdas vencidas llevan el icono schedule', (tester) async {
    seed('C', seen: 10, correct: 9);
    srs.noteData['C']!.nextReview =
        _now.subtract(const Duration(days: 2)).toIso8601String();
    await pumpScreen(tester, history: [log(0)]);

    expect(find.byKey(const ValueKey('mastery-due-C')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^C, 90 %, .*, pendiente de repaso$')),
      findsWidgets,
    );
  });

  testWidgets('KPI «Pendientes» abre la sesión de hoy', (tester) async {
    seed('C', seen: 10, correct: 9);
    await pumpScreen(tester, history: [log(0)], grid: false);

    await tester.tap(find.byKey(const Key('progress-kpi-pending')));
    await tester.pumpAndSettle();
    expect(find.text('GAME ${GameMode.singleNote.id}'), findsOneWidget);
  });

  testWidgets('«Tus extremos»: Pro ve difíciles y fáciles; gratis, candado', (
    tester,
  ) async {
    seed('C', seen: 10, correct: 2);
    seed('D', seen: 10, correct: 5);
    seed('E', seen: 10, correct: 7);
    seed('F', seen: 10, correct: 8);
    seed('G', seen: 10, correct: 9);
    seed('A', seen: 10, correct: 10);
    await pumpScreen(tester, history: [log(0)], grid: false);

    final hard = find.byKey(const Key('progress-extremes-hard'));
    final easy = find.byKey(const Key('progress-extremes-easy'));
    expect(hard, findsOneWidget);
    expect(
      find.descendant(of: hard, matching: find.text('20 %')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: easy, matching: find.text('100 %')),
      findsOneWidget,
    );
  });

  testWidgets('«Tus extremos» sin Pro: candado al paywall', (tester) async {
    seed('C', seen: 10, correct: 2);
    seed('D', seen: 10, correct: 9);
    await pumpScreen(tester, pro: false, history: [log(0)], grid: false);

    final locked = find.byKey(const Key('progress-extremes-locked'));
    expect(locked, findsOneWidget);
    expect(find.byKey(const Key('progress-extremes-hard')), findsNothing);
    await tester.ensureVisible(locked);
    await tester.tap(locked);
    await tester.pumpAndSettle();
    expect(find.text('PAYWALL'), findsOneWidget);
  });

  testWidgets('web ancho: contenido centrado con ancho máximo', (
    tester,
  ) async {
    seed('C', seen: 10, correct: 9);
    await tester.binding.setSurfaceSize(const Size(1400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildApp(history: [log(0)]));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byKey(const Key('progress-content')));
    expect(size.width, lessThanOrEqualTo(StatisticsScreen.maxContentWidth));
    final center = tester.getCenter(find.byKey(const Key('progress-content')));
    expect(center.dx, closeTo(700, 1));
  });
}

class _FakeSRSNotifier extends AsyncNotifier<SRSSystem> implements SRSNotifier {
  final SRSSystem _srs;
  _FakeSRSNotifier(this._srs);

  @override
  Future<SRSSystem> build() async => _srs;

  @override
  Future<void> saveProgress() async => _srs.saveProgress();

  @override
  Future<void> resetProgress() async {
    await _srs.resetProgress();
    ref.invalidateSelf();
  }
}

class _FakeSessionHistoryNotifier extends SessionHistoryNotifier {
  final List<PracticeSessionLog> _entries;
  _FakeSessionHistoryNotifier(this._entries);

  @override
  Future<List<PracticeSessionLog>> build() async => _entries;
}
