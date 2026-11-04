import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/constants/game_constants.dart';
import 'package:togesc/providers/game_session_provider.dart';
import 'package:togesc/services/app_preferences.dart';
import 'package:togesc/widgets/piano_keyboard.dart';

import 'qa_support.dart';

/// Toca una tecla como un usuario: las blancas por su parte baja (la mitad
/// superior queda bajo la zona táctil de 48 dp de las negras) y las negras
/// por su centro.
Future<void> _tapKey(WidgetTester tester, String note) async {
  final rect = tester.getRect(find.byKey(ValueKey('piano-key-$note')));
  final point = note.contains('#')
      ? rect.center
      : rect.bottomCenter - const Offset(0, 16);
  await tester.tapAt(point);
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  group('GameScreen · envío inmediato (confirmBeforeSubmit = false)', () {
    testWidgets('dos toques rápidos en teclas distintas cuentan una sola '
        'ronda', (tester) async {
      final (container, srs) = await qaGameContainer(
        tester,
        focusNote: 'D',
        prefs: {confirmBeforeSubmitV2Key: false},
      );
      await qaPumpGameToAnswer(tester, container: container);

      // Ambos toques en el mismo frame: el segundo llega antes de que la
      // pantalla se reconstruya con el teclado deshabilitado.
      await _tapKey(tester, 'D');
      await _tapKey(tester, 'E');
      await tester.pump(const Duration(milliseconds: 100));

      final session = container.read(gameSessionProvider);
      expect(session.roundsCompleted, 1);
      expect(session.correctRounds, 1);
      expect(session.lastResult?.wrongNotes ?? const <String>{}, isEmpty);
      expect(srs.noteData['D']!.timesSeen, 1);
      expect(srs.noteData['E']!.timesSeen, 0);
      expect(find.text('CORRECTO'), findsOneWidget);
      await qaPumpFor(tester, const Duration(milliseconds: 2400));
    });

    testWidgets('dos atajos de teclado seguidos cuentan una sola ronda', (
      tester,
    ) async {
      final (container, srs) = await qaGameContainer(
        tester,
        focusNote: 'D',
        prefs: {confirmBeforeSubmitV2Key: false},
      );
      await qaPumpGameToAnswer(tester, container: container);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump(const Duration(milliseconds: 100));

      final session = container.read(gameSessionProvider);
      expect(session.roundsCompleted, 1);
      expect(session.correctRounds, 0);
      expect(srs.noteData['D']!.timesSeen, 1);
      expect(find.text('INCORRECTO'), findsOneWidget);
      await qaPumpFor(tester, const Duration(milliseconds: 2400));
    });

    testWidgets('doble toque en la misma tecla no envía dos veces', (
      tester,
    ) async {
      final (container, srs) = await qaGameContainer(
        tester,
        focusNote: 'D',
        prefs: {confirmBeforeSubmitV2Key: false},
      );
      await qaPumpGameToAnswer(tester, container: container);

      await _tapKey(tester, 'D');
      await _tapKey(tester, 'D');
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(gameSessionProvider).roundsCompleted, 1);
      expect(srs.noteData['D']!.timesSeen, 1);
      await qaPumpFor(tester, const Duration(milliseconds: 2400));
    });
  });

  group('GameScreen · pool de notas pequeño', () {
    for (final mode in const [GameMode.chord, GameMode.random]) {
      testWidgets('pool de 2 notas y modo ${mode.name}: la ronda arranca sin '
          'excepción', (tester) async {
        final (container, _) = await qaGameContainer(
          tester,
          prefs: {
            practiceNotePoolKey: ['C', 'D'],
          },
        );
        await qaPumpGameToAnswer(tester, container: container, mode: mode);

        expect(tester.takeException(), isNull);
        final session = container.read(gameSessionProvider);
        expect(session.state, GameState.waitingForAnswer);
        expect(session.currentNotes, isNotEmpty);
        // Notas distintas: el SRS no repite nota dentro de la ronda.
        expect(
          session.currentNotes.toSet(),
          hasLength(session.currentNotes.length),
        );
        expect(find.byType(PianoKeyboard), findsOneWidget);
      });
    }

    testWidgets('pool de 2 notas y modo chord: se puede responder la ronda', (
      tester,
    ) async {
      final (container, _) = await qaGameContainer(
        tester,
        prefs: {
          practiceNotePoolKey: ['C', 'D'],
        },
      );
      await qaPumpGameToAnswer(
        tester,
        container: container,
        mode: GameMode.chord,
      );
      final target = container.read(gameSessionProvider).currentNotes;
      expect(target, hasLength(3));
      for (final note in target) {
        await _tapKey(tester, note);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(container.read(gameSessionProvider).roundsCompleted, 1);
      expect(find.text('CORRECTO'), findsOneWidget);
      await qaPumpFor(tester, const Duration(milliseconds: 2400));
    });
  });
}
