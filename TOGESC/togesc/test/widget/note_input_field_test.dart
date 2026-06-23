import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/widgets/note_input_field.dart';

void main() {
  Widget buildApp({
    required ValueChanged<List<String>> onSubmitted,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: NoteInputField(
            onSubmitted: onSubmitted,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  Future<void> submitField(WidgetTester tester) async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  group('NoteInputField', () {
    testWidgets('tiene campo de texto command-bar', (tester) async {
      await tester.pumpWidget(buildApp(onSubmitted: (_) {}));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('INPUT'), findsOneWidget);
    });

    testWidgets('parsea notas separadas por espacios', (tester) async {
      List<String>? result;
      await tester.pumpWidget(buildApp(onSubmitted: (notes) => result = notes));

      await tester.enterText(find.byType(TextField), 'C E G');
      await submitField(tester);

      expect(result, ['C', 'E', 'G']);
    });

    testWidgets('convierte a mayusculas', (tester) async {
      List<String>? result;
      await tester.pumpWidget(buildApp(onSubmitted: (notes) => result = notes));

      await tester.enterText(find.byType(TextField), 'c d e');
      await submitField(tester);

      expect(result, ['C', 'D', 'E']);
    });

    testWidgets('normaliza enarmonias', (tester) async {
      List<String>? result;
      await tester.pumpWidget(buildApp(onSubmitted: (notes) => result = notes));

      await tester.enterText(find.byType(TextField), 'Db Eb');
      await submitField(tester);

      expect(result, ['C#', 'D#']);
    });

    testWidgets('no envia cadena vacia', (tester) async {
      List<String>? result;
      await tester.pumpWidget(buildApp(onSubmitted: (notes) => result = notes));

      await submitField(tester);

      expect(result, isNull);
    });

    testWidgets('limpia campo despues de enviar', (tester) async {
      await tester.pumpWidget(buildApp(onSubmitted: (_) {}));

      await tester.enterText(find.byType(TextField), 'C E G');
      await submitField(tester);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '');
    });

    testWidgets('campo deshabilitado cuando enabled=false', (tester) async {
      await tester.pumpWidget(buildApp(
        onSubmitted: (_) {},
        enabled: false,
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });
  });
}
