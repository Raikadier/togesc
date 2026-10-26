import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../integration_test/support/e2e_harness.dart';

void main() {
  testWidgets('web path', (tester) async {
    final got = <String>[];
    await tester.pumpWidget(MaterialApp(home: Focus(autofocus: true,
      onKeyEvent: (n, e) { if (e is KeyDownEvent) got.add('${HardwareKeyboard.instance.isShiftPressed ? "S+" : ""}${e.logicalKey.keyLabel}'); return KeyEventResult.handled; },
      child: const SizedBox())));
    await tester.pump();
    await sendShortcut(tester, 'D', webPath: true);
    await sendShortcut(tester, 'C', shift: true, webPath: true);
    await sendShortcut(tester, ' ', webPath: true);
    await sendShortcut(tester, 'R', webPath: true);
    debugPrint('got=$got');
    expect(got, ['D', 'S+Shift Left', 'S+C', ' ', 'R']);
  });
}
