import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/e2e_harness.dart';

/// El camino web de `sendShortcut` (KeyData + mensaje crudo `keymap: web`)
/// se usa en Chrome release, donde `simulateKeyDownEvent` falla porque los
/// mapas de teclado de flutter_test se eliminan por tree-shaking. Aquí se
/// comprueba en VM que esos eventos llegan bien al framework.
void main() {
  testWidgets('sendShortcut (camino web) entrega letra, ⇧, Espacio y R', (
    tester,
  ) async {
    final received = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final shift = HardwareKeyboard.instance.isShiftPressed;
              received.add('${shift ? '⇧' : ''}${event.logicalKey.keyLabel}');
            }
            return KeyEventResult.handled;
          },
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    await sendShortcut(tester, 'D', webPath: true);
    await sendShortcut(tester, 'C', shift: true, webPath: true);
    await sendShortcut(tester, ' ', webPath: true);
    await sendShortcut(tester, 'R', webPath: true);

    expect(received, ['D', '⇧Shift Left', '⇧C', ' ', 'R']);
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
  });
}
