// A11Y · Semantics del piano de sesión (Juego, fase «Responde»).
//
// Lo que un lector de pantalla necesita de cada tecla: nombre, rol de
// botón, estado (activa/desactivada, seleccionada, correcta/incorrecta) y
// que la acción «activar» del propio nodo con nombre responda la ronda.
// La pronunciación real («C sostenido» frente a «C almohadilla») solo se
// puede confirmar con TalkBack/VoiceOver: aquí se comprueba el texto.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/app/router.dart';
import 'package:togesc/main.dart';
import 'package:togesc/models/practice_session_log.dart' show chromaticNotes;
import 'package:togesc/providers/game_session_provider.dart';
import 'package:togesc/widgets/piano_keyboard.dart';

import 'a11y_harness.dart';

const _game = A11yScreen('Juego', '${AppRoutes.game}/1');

SemanticsNode _key(WidgetTester tester, String note) => tester.getSemantics(
  find.descendant(
    of: find.byType(PianoKeyboard),
    matching: find.bySemanticsLabel(note),
  ),
);

Future<void> _toAnswer(WidgetTester tester) async {
  await pumpA11yScreen(
    tester,
    _game,
    size: const Size(390, 844),
    settle: false,
  );
  await pumpFor(tester, const Duration(seconds: 1));
  await startGameSession(tester);
  expect(find.text('RESPONDE'), findsOneWidget);
}

List<String> _currentNotes(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(TogescApp)),
).read(gameSessionProvider).currentNotes;

void main() {
  testWidgets('las 12 teclas tienen nombre, rol de botón y están activas', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _toAnswer(tester);
      expect(find.bySemanticsLabel('Teclado de piano'), findsOneWidget);
      for (final note in chromaticNotes) {
        final data = _key(tester, note).getSemanticsData();
        final flags = data.flagsCollection;
        expect(flags.isButton, isTrue, reason: note);
        expect(flags.isEnabled, ui.Tristate.isTrue, reason: note);
        // Tiene estado «seleccionada» (aunque ahora no lo esté).
        expect(flags.isSelected, ui.Tristate.isFalse, reason: note);
      }
    } finally {
      await leaveA11yScreen(tester);
      handle.dispose();
    }
  });

  testWidgets('mientras suena la nota las teclas se anuncian desactivadas', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await pumpA11yScreen(
        tester,
        _game,
        size: const Size(390, 844),
        settle: false,
      );
      await pumpFor(tester, const Duration(seconds: 1));
      await startGameSession(tester);
      // «Repetir» vuelve a la fase de escucha.
      await tester.tap(find.text('Repetir'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ESCUCHANDO'), findsOneWidget);
      for (final note in chromaticNotes) {
        final data = _key(tester, note).getSemanticsData();
        expect(
          data.flagsCollection.isEnabled,
          ui.Tristate.isFalse,
          reason: note,
        );
      }
    } finally {
      await leaveA11yScreen(tester);
      handle.dispose();
    }
  });

  testWidgets('tras responder, la tecla correcta lleva el estado «correcta»', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _toAnswer(tester);
      final answer = _currentNotes(tester).single;
      final wrong = answer == 'C' ? 'D' : 'C';
      await tester.tap(find.byKey(ValueKey('piano-key-$wrong')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_key(tester, answer).hint, 'correcta');
      expect(_key(tester, wrong).hint, 'incorrecta');
      // El resultado se anuncia en una región viva.
      final live = find.bySemanticsLabel(RegExp('^Incorrecto'));
      expect(live, findsWidgets);
      expect(
        tester.getSemantics(live.first).flagsCollection.isLiveRegion,
        isTrue,
      );
    } finally {
      await leaveA11yScreen(tester);
      handle.dispose();
    }
  });

  a11yTestWidgets('el nodo con nombre de cada tecla tiene la acción «tap»', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _toAnswer(tester);
      for (final note in chromaticNotes) {
        final data = _key(tester, note).getSemanticsData();
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue, reason: note);
      }
    } finally {
      await leaveA11yScreen(tester);
      handle.dispose();
    }
  });

  a11yTestWidgets(
    'activar la tecla por Semantics (doble toque del lector) responde',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _toAnswer(tester);
        final answer = _currentNotes(tester).single;
        tester.semantics.tap(find.semantics.byLabel(answer));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.bySemanticsLabel(RegExp('^Correcto')), findsWidgets);
      } finally {
        await leaveA11yScreen(tester);
        handle.dispose();
      }
    },
  );

  a11yTestWidgets(
    'las negras se nombran «sostenido», no con «#»',
    barrier:
        'A11Y: las teclas negras se etiquetan «C#», «D#»… '
        '(lib/widgets/piano_keyboard.dart:168, formatNoteLabel); el lector '
        'lee «C almohadilla/número». El mapa del oído ya dice «C sostenido»; '
        'WCAG 1.3.1/4.1.2 (verificar con TalkBack/VoiceOver)',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _toAnswer(tester);
        expect(
          find.descendant(
            of: find.byType(PianoKeyboard),
            matching: find.bySemanticsLabel(RegExp('#')),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(PianoKeyboard),
            matching: find.bySemanticsLabel('C sostenido'),
          ),
          findsOneWidget,
        );
      } finally {
        await leaveA11yScreen(tester);
        handle.dispose();
      }
    },
  );
}
