import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/widgets/piano_keyboard.dart';

import 'qa_support.dart';

/// Geometría del piano de sesión dentro de GameScreen en móviles estrechos.
///
/// `piano_keyboard.dart` fija `minWidth = 352` (7 × 48 + 16). En 360 y 375
/// el hueco real es 360 − 32 = 328 y 375 − 32 = 343: el contenedor se encoge
/// a lo disponible, pero las negras se posicionan con el ancho teórico.
void main() {
  const tolerance = 2.0;

  Future<void> pumpGameAt(WidgetTester tester, Size size) async {
    final (container, _) = await qaGameContainer(tester, focusNote: 'D');
    await qaPumpGameToAnswer(tester, container: container, size: size);
  }

  /// Desfase (px) de cada negra respecto a la frontera de sus dos blancas.
  Map<String, double> blackKeyOffsets(WidgetTester tester) {
    final offsets = <String, double>{};
    const whites = PianoKeyboard.whiteNotes;
    for (final entry in PianoKeyboard.blackNoteMap.entries) {
      final left = entry.key;
      final right = whites[whites.indexOf(left) + 1];
      final leftRect = tester.getRect(find.byKey(ValueKey('piano-key-$left')));
      final rightRect = tester.getRect(
        find.byKey(ValueKey('piano-key-$right')),
      );
      final boundary = (leftRect.right + rightRect.left) / 2;
      final black = tester.getRect(
        find.byKey(ValueKey('piano-key-${entry.value}')),
      );
      offsets[entry.value] = (black.center.dx - boundary).abs();
    }
    return offsets;
  }

  void expectInsideScreen(WidgetTester tester, Size size) {
    final box = tester.getRect(
      find.byKey(const ValueKey('piano-session-container')),
    );
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(size.width));
    for (final note in [
      ...PianoKeyboard.whiteNotes,
      ...PianoKeyboard.blackNoteMap.values,
    ]) {
      final key = tester.getRect(find.byKey(ValueKey('piano-key-$note')));
      expect(key.left, greaterThanOrEqualTo(box.left - 0.5), reason: note);
      expect(key.right, lessThanOrEqualTo(box.right + 0.5), reason: note);
    }
  }

  // Control: a 390 de ancho hay sitio (390 − 32 = 358 ≥ 352).
  testWidgets('390×844 (control): negras centradas y sin overflow', (
    tester,
  ) async {
    await pumpGameAt(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    expectInsideScreen(tester, const Size(390, 844));
    blackKeyOffsets(tester).forEach((note, off) {
      expect(off, lessThanOrEqualTo(tolerance), reason: '$note: $off px');
    });
  });

  for (final size in const [Size(360, 800), Size(375, 812)]) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';

    testWidgets('$label: el teclado no se sale de la pantalla ni lanza '
        'overflow', (tester) async {
      await pumpGameAt(tester, size);
      expect(tester.takeException(), isNull);
      expectInsideScreen(tester, size);
    });

    testWidgets('$label: cada negra centrada sobre la frontera de sus '
        'blancas (±2 px)', (tester) async {
      await pumpGameAt(tester, size);
      final offsets = blackKeyOffsets(tester);
      final worst = offsets.values.reduce((a, b) => a > b ? a : b);
      expect(
        worst,
        lessThanOrEqualTo(tolerance),
        reason: offsets
            .map((k, v) => MapEntry(k, v.toStringAsFixed(1)))
            .toString(),
      );
    });
  }
}
