import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/app/app_theme.dart';
import 'package:togesc/app/design_tokens.dart';
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
      theme: AppTheme.light,
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
      await tester.pumpWidget(
        buildApp(onNoteTapped: (note) => tappedNote = note),
      );

      await tester.tap(find.text('C'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedNote, 'C');

      await tester.tap(find.text('G'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedNote, 'G');
    });

    testWidgets('tap en tecla negra invoca callback con nota sostenida', (
      tester,
    ) async {
      String? tappedNote;
      await tester.pumpWidget(
        buildApp(onNoteTapped: (note) => tappedNote = note),
      );

      await tester.tap(find.text('C#'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tappedNote, 'C#');
    });

    testWidgets('disabled=true no invoca callback', (tester) async {
      String? tappedNote;
      await tester.pumpWidget(
        buildApp(onNoteTapped: (note) => tappedNote = note, disabled: true),
      );

      await tester.tap(find.text('C'));
      expect(tappedNote, isNull);
    });

    testWidgets('se renderiza correctamente', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byType(PianoKeyboard), findsOneWidget);
    });

    testWidgets('teclas blancas exponen Semantics con nombre de nota', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      final semantics = tester.getSemantics(find.bySemanticsLabel('C'));
      expect(semantics.label, 'C');
      expect(semantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('nota correcta muestra icono y hint en Semantics', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(correctNotes: {'D'}));

      expect(find.byIcon(Icons.check_circle), findsWidgets);
      final semantics = tester.getSemantics(find.bySemanticsLabel('D'));
      expect(semantics.hint, 'correcta');
    });
  });

  group('PianoKeyboard · variante de sesión v2', () {
    Widget buildSession({
      PianoKeyboardVariant variant = PianoKeyboardVariant.session,
      double width = 390,
      Set<String> correctNotes = const {},
      Set<String> incorrectNotes = const {},
      bool dimOthers = false,
      ValueChanged<String>? onNoteTapped,
    }) {
      return MaterialApp(
        theme: AppTheme.session,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: PianoKeyboard(
                variant: variant,
                correctNotes: correctNotes,
                incorrectNotes: incorrectNotes,
                dimOthers: dimOthers,
                onNoteTapped: onNoteTapped,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('móvil: 230 de alto y negras de 38×140', (tester) async {
      await tester.pumpWidget(buildSession());
      expect(
        tester
            .getSize(find.byKey(const ValueKey('piano-session-container')))
            .height,
        230,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('piano-key-F#'))),
        const Size(38, 140),
      );
    });

    testWidgets('negras: zona táctil de 48 aunque midan 38', (tester) async {
      String? tapped;
      await tester.pumpWidget(buildSession(onNoteTapped: (n) => tapped = n));
      final rect = tester.getRect(find.byKey(const ValueKey('piano-key-C#')));
      // 4 px fuera del dibujo de la tecla, aún dentro de la zona de 48.
      await tester.tapAt(Offset(rect.right + 4, rect.top + 40));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, 'C#');
      final semantics = tester.getSemantics(find.bySemanticsLabel('C#'));
      expect(semantics.rect.width, greaterThanOrEqualTo(48));
    });

    testWidgets('escritorio: 210 de alto y negras de 52×126', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        buildSession(variant: PianoKeyboardVariant.sessionWide, width: 900),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('piano-session-container')))
            .height,
        210,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('piano-key-A#'))),
        const Size(52, 126),
      );
    });

    testWidgets('feedback con badges ✓/✗ además del color y resto atenuado',
        (tester) async {
      await tester.pumpWidget(
        buildSession(
          correctNotes: {'D'},
          incorrectNotes: {'F#'},
          dimOthers: true,
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('D')).hint, 'correcta');
      expect(
        tester.getSemantics(find.bySemanticsLabel('F#')).hint,
        'incorrecta',
      );

      BoxDecoration deco(String note) => tester
          .widget<AnimatedContainer>(find.byKey(ValueKey('piano-key-$note')))
          .decoration! as BoxDecoration;
      expect(deco('D').gradient, DesignTokens.pianoWhiteKeyCorrectGradient);
      expect(deco('F#').gradient, DesignTokens.pianoBlackKeyWrongGradient);
      expect(deco('E').gradient, DesignTokens.pianoWhiteKeyDimmedGradient);
      expect(deco('C#').gradient, DesignTokens.pianoBlackKeyDimmedGradient);
    });

    testWidgets('a 320 px no desborda', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.session,
          home: const Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: PianoKeyboard(variant: PianoKeyboardVariant.session),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
