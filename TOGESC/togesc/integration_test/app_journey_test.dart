// Tests de dispositivo del rediseño v2 (Android y Chrome).
//
// Android:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_journey_test.dart -d emulator-5554
// Chrome (con `chromedriver --port=4444` en marcha):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_journey_test.dart -d chrome
//
// Las capturas quedan en build/evidence/<plataforma>/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:togesc/screens/account_screen.dart';
import 'package:togesc/screens/game_screen.dart';
import 'package:togesc/screens/home_screen.dart';
import 'package:togesc/screens/speed_mode_select_screen.dart';
import 'package:togesc/screens/statistics_screen.dart';
import 'package:togesc/screens/subscription_screen.dart';
import 'package:togesc/widgets/piano_keyboard.dart';
import 'package:togesc/widgets/togesc_shell.dart';

import 'support/e2e_harness.dart';

/// Teléfono de referencia y escritorio (≥1024, rail + layout 1d).
const _phone = Size(412, 915);
const _desktop = Size(1280, 800);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Fija el tamaño lógico para que móvil y escritorio no dependan de la
  /// ventana de Chrome ni del emulador (la vista se escala para caber).
  ///
  /// `tester.view` fija el tamaño lógico que ve `MediaQuery` (y con él los
  /// breakpoints); `setSurfaceSize` escala ese lienzo a la pantalla real.
  Future<void> useSurface(WidgetTester tester, Size size) async {
    final dpr = tester.view.devicePixelRatio;
    tester.view.physicalSize = size * dpr;
    addTearDown(tester.view.resetPhysicalSize);
    await binding.setSurfaceSize(size);
    addTearDown(() => binding.setSurfaceSize(null));
  }

  Finder nav(TogescNavDestination d) => find.byKey(ValueKey('nav-${d.name}'));
  Finder rail(TogescNavDestination d) => find.byKey(ValueKey('rail-${d.name}'));
  Finder roundChip(int round) => find.descendant(
    of: find.byKey(const ValueKey('session-chip-round')),
    matching: find.textContaining('$round / $e2eTargetRounds'),
  );
  PianoKeyboard piano(WidgetTester tester) =>
      tester.widget<PianoKeyboard>(find.byType(PianoKeyboard));

  /// Espera listen → answer de la ronda [round] y devuelve la nota pedida.
  Future<String> reachAnswer(WidgetTester tester, E2EApp app, int round) async {
    await pumpUntilFound(tester, roundChip(round), reason: 'ronda $round');
    await pumpUntilFound(
      tester,
      find.text('RESPONDE'),
      reason: 'ronda $round en answer',
    );
    final notes = app.session.currentNotes;
    expect(notes, hasLength(1), reason: 'la sesión de hoy es de una nota');
    return notes.single;
  }

  Future<void> tapPianoKey(WidgetTester tester, String note) async {
    // Las blancas quedan tapadas por las negras en su mitad superior: se
    // toca la franja inferior, como un dedo real.
    final key = find.byKey(ValueKey('piano-key-$note'));
    final rect = tester.getRect(key);
    await tester.tapAt(
      note.endsWith('#')
          ? rect.center
          : rect.bottomCenter - const Offset(0, 16),
    );
    await tester.pump();
  }

  setUp(() {
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() {
    WidgetController.hitTestWarningShouldBeFatal = false;
  });

  testWidgets('móvil: Home → sesión corta → Progreso → pestañas → Pro', (
    tester,
  ) async {
    await useSurface(tester, _phone);
    final evidence = Evidence(binding);
    final app = await E2EApp.pump(tester);
    await evidence.prepare(tester);

    // Home v2.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('today-session-hero')), findsOneWidget);
    expect(find.byType(TogescBottomNav), findsOneWidget);
    await evidence.shot(tester, '01_home');

    // CTA → «Preparado» (v2.1) → «Estoy listo» arranca la escucha.
    await scrollAndTap(tester, find.byKey(const ValueKey('today-start-cta')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('session-start')));
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('PREPARADO'), findsOneWidget);
    await evidence.shot(tester, '02a_session_ready');
    await tester.tap(find.byKey(const ValueKey('session-start')));
    await pumpUntilFound(tester, find.text('ESCUCHANDO'));
    await evidence.shot(tester, '02_session_listen');

    // Ronda 1: acierto, la tecla queda en verde.
    final first = await reachAnswer(tester, app, 1);
    await evidence.shot(tester, '03_session_answer');
    await tapPianoKey(tester, first);
    await pumpUntilFound(tester, find.text('CORRECTO'));
    expect(piano(tester).correctNotes, {first});
    expect(piano(tester).incorrectNotes, isEmpty);
    await evidence.shot(tester, '04_result_correct');

    // Avance automático (2,2 s) sin tocar nada → ronda 2: fallo.
    final second = await reachAnswer(tester, app, 2);
    final wrong = second == 'C' ? 'D' : 'C';
    await tapPianoKey(tester, wrong);
    await pumpUntilFound(tester, find.text('INCORRECTO'));
    expect(find.text('Era $second, respondiste $wrong'), findsOneWidget);
    expect(piano(tester).correctNotes, {second});
    expect(piano(tester).incorrectNotes, {wrong});
    await evidence.shot(tester, '05_result_wrong');

    // Resto de rondas: aciertos hasta la meta.
    for (var round = 3; round <= e2eTargetRounds; round++) {
      final note = await reachAnswer(tester, app, round);
      await tapPianoKey(tester, note);
      await pumpUntilFound(tester, find.text('CORRECTO'));
    }
    // Meta cumplida → resumen de la sesión.
    await pumpUntilFound(tester, find.byKey(const ValueKey('session-summary')));
    expect(app.session.goalReached, isTrue);
    expect(app.session.correctRounds, e2eTargetRounds - 1);
    expect(
      find.text('${e2eTargetRounds - 1}/$e2eTargetRounds'),
      findsOneWidget,
    );
    await evidence.shot(tester, '13_session_summary');
    await scrollAndTap(
      tester,
      find.byKey(const ValueKey('session-summary-home')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // Progreso refleja la sesión.
    await tester.tap(nav(TogescNavDestination.progress));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsScreen), findsOneWidget);
    expect(find.byKey(const Key('progress-empty-state')), findsNothing);
    await evidence.shot(tester, '06_progress');
    final row = find.text(
      '$e2eTargetRounds rondas · ${e2eTargetRounds - 1} aciertos',
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(row, findsOneWidget);
    await evidence.shot(tester, '06b_progress_sessions');

    // Pestañas restantes.
    await tester.tap(nav(TogescNavDestination.speed));
    await tester.pumpAndSettle();
    expect(find.byType(SpeedModeSelectScreen), findsOneWidget);

    await tester.tap(nav(TogescNavDestination.profile));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    await evidence.shot(tester, '07_profile');

    // Pro vive dentro de Perfil (D8).
    await scrollAndTap(tester, find.byKey(const ValueKey('account-pro-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionScreen), findsOneWidget);

    await tester.tap(nav(TogescNavDestination.practice));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('escritorio ≥1024: rail, panel SRS y atajos de teclado', (
    tester,
  ) async {
    await useSurface(tester, _desktop);
    final evidence = Evidence(binding);
    final app = await E2EApp.pump(tester);
    await evidence.prepare(tester);

    expect(find.byType(TogescNavRail), findsOneWidget);
    expect(find.byType(TogescBottomNav), findsNothing);
    for (final d in TogescNavDestination.values) {
      expect(rail(d), findsOneWidget, reason: d.label);
    }
    await evidence.shot(tester, '08_desktop_home');

    await scrollAndTap(tester, find.byKey(const ValueKey('today-start-cta')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('session-start')));
    await tester.tap(find.byKey(const ValueKey('session-start')));
    final first = await reachAnswer(tester, app, 1);
    expect(find.byKey(const ValueKey('session-srs-panel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('session-shortcuts-legend')),
      findsOneWidget,
    );
    expect(piano(tester).variant, PianoKeyboardVariant.sessionWide);
    await evidence.shot(tester, '09_desktop_answer');

    await traced(binding, () async {
      // Letra (⇧ para sostenidos) responde sin tocar el piano.
      e2eStep(
        binding,
        'desktop: Letra (⇧ para sostenidos) responde sin tocar el piano.',
      );
      await sendNoteShortcut(tester, first);
      await pumpUntilFound(tester, find.text('CORRECTO'));
      expect(piano(tester).correctNotes, {first});
      await evidence.shot(tester, '10_desktop_result_correct');

      // Espacio salta la espera del resultado.
      e2eStep(binding, 'desktop: Espacio salta la espera del resultado.');
      await sendShortcut(tester, ' ');
      await tester.pump();
      expect(find.text('CORRECTO'), findsNothing);
      final second = await reachAnswer(tester, app, 2);

      // R repite la misma ronda sin contarla.
      e2eStep(binding, 'desktop: R repite la misma ronda sin contarla.');
      await sendShortcut(tester, 'R');
      await pumpUntilFound(tester, find.text('ESCUCHANDO'));
      await pumpUntilFound(tester, find.text('RESPONDE'));
      expect(app.session.currentNotes, [second]);
      expect(app.session.roundsCompleted, 1);

      // Fallo por teclado: correcta en verde y errónea en rojo.
      e2eStep(
        binding,
        'desktop: Fallo por teclado: correcta en verde y errónea en rojo.',
      );
      final wrong = second == 'C' ? 'D' : 'C';
      await sendNoteShortcut(tester, wrong);
      await pumpUntilFound(tester, find.text('INCORRECTO'));
      expect(piano(tester).incorrectNotes, {wrong});
      await evidence.shot(tester, '11_desktop_result_wrong');

      // Esc pausa; «Salir sin guardar» y Progreso desde el rail.
      e2eStep(binding, 'desktop: Esc pausa y «Salir sin guardar» sale.');
      await sendShortcut(tester, 'Escape');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-pause-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('session-pause-exit')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.tap(rail(TogescNavDestination.progress));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });
    await evidence.shot(tester, '12_desktop_progress');
    expect(tester.takeException(), isNull);
  });
}
