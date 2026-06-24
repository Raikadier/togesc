import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/widgets/piano_keyboard.dart';

void main() {
  Widget buildApp({
    Set<String> selectedNotes = const {},
    Set<String> correctNotes = const {},
    Set<String> incorrectNotes = const {},
    ValueChanged<String>? onNoteTapped,
    bool disabled = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: PianoKeyboard(
              selectedNotes: selectedNotes,
              correctNotes: correctNotes,
              incorrectNotes: incorrectNotes,
              onNoteTapped: onNoteTapped,
              disabled: disabled,
            ),
          ),
        ),
      ),
    );
  }

  group('PianoKeyboard', () {
    testWidgets('muestra 7 teclas blancas con nombres', (tester) async {
      await tester.pumpWidget(buildApp());

      for (final note in ['C', 'D', 'E', 'F', 'G', 'A', 'B']) {
        expect(find.text(note), findsOneWidget);
      }
    });

    testWidgets('muestra 5 teclas negras con nombres', (tester) async {
      await tester.pumpWidget(buildApp());

      for (final note in ['C#', 'D#', 'F#', 'G#', 'A#']) {
        expect(find.text(note), findsOneWidget);
      }
    });

    testWidgets('tap en tecla blanca invoca callback con nota', (tester) async {
      String? tappedNote;
      await tester.pumpWidget(buildApp(
        onNoteTapped: (note) => tappedNote = note,
      ));

      await tester.tap(find.text('C'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedNote, 'C');

      await tester.tap(find.text('G'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedNote, 'G');
    });

    testWidgets('tap en tecla negra invoca callback con nota sostenida', (tester) async {
      String? tappedNote;
      await tester.pumpWidget(buildApp(
        onNoteTapped: (note) => tappedNote = note,
      ));

      await tester.tap(find.text('C#'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedNote, 'C#');
    });

    testWidgets('disabled=true no invoca callback', (tester) async {
      String? tappedNote;
      await tester.pumpWidget(buildApp(
        onNoteTapped: (note) => tappedNote = note,
        disabled: true,
      ));

      await tester.tap(find.text('C'));
      expect(tappedNote, isNull);
    });

    testWidgets('se renderiza correctamente', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byType(PianoKeyboard), findsOneWidget);
    });

    testWidgets('teclas blancas exponen Semantics con nombre de nota', (tester) async {
      await tester.pumpWidget(buildApp());

      final semantics = tester.getSemantics(find.bySemanticsLabel('C'));
      expect(semantics.label, 'C');
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('nota correcta muestra icono y hint en Semantics', (tester) async {
      await tester.pumpWidget(buildApp(correctNotes: {'D'}));

      expect(find.byIcon(Icons.check_circle), findsWidgets);
      final semantics = tester.getSemantics(find.bySemanticsLabel('D'));
      expect(semantics.hint, 'correcta');
    });
  });
}
