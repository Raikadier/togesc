import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/app/app_theme.dart';
import 'package:togesc/constants/note_naming.dart';
import 'package:togesc/models/note_progress_summary.dart';
import 'package:togesc/models/practice_session_log.dart' show chromaticNotes;
import 'package:togesc/widgets/ear_map/ear_map_wheel.dart';

NoteProgressSummary _summary(
  String note, {
  int seen = 10,
  int correct = 5,
  bool learning = true,
  int consecutive = 2,
}) {
  return NoteProgressSummary(
    note: note,
    isLearning: learning,
    consecutiveCorrect: consecutive,
    timesSeen: seen,
    timesCorrect: correct,
    weight: 1,
    isOverdue: false,
  );
}

void main() {
  Widget buildApp({
    List<NoteProgressSummary>? summaries,
    ValueChanged<NoteProgressSummary>? onSelect,
    ValueChanged<NoteProgressSummary?>? onHover,
    bool reduceMotion = false,
    ThemeData? theme,
    bool onDark = false,
    NoteNamingMode namingMode = NoteNamingMode.letter,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: EarMapWheel(
                summaries:
                    summaries ??
                    [
                      for (final n in chromaticNotes)
                        _summary(n, correct: n == 'C#' ? 4 : 8),
                    ],
                centerValue: '68 %',
                centerCaption: 'Precisión global',
                onSelect: onSelect,
                onHover: onHover,
                onDark: onDark,
                namingMode: namingMode,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('EarMapWheel', () {
    testWidgets('expone 12 segmentos con su etiqueta semántica', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildApp(onSelect: (_) {}));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Mapa del oído: dominio de las 12 notas'),
        findsOneWidget,
      );
      for (final note in chromaticNotes) {
        expect(
          find.byKey(ValueKey('ear-map-segment-$note')),
          findsOneWidget,
          reason: note,
        );
      }
      // C#: 4/10 = 40 % → crítica; nivel 1 (2 aciertos seguidos, umbral 5).
      expect(
        find.bySemanticsLabel('C sostenido, 40 %, crítica, nivel 1 de 5'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('D, 80 %, dominada, nivel 1 de 5'),
        findsOneWidget,
      );
      final data = tester
          .getSemantics(find.byKey(const ValueKey('ear-map-segment-C')))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('notas sin datos se leen como «sin datos todavía»', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildApp(summaries: [_summary('C')], reduceMotion: true),
      );
      expect(
        find.bySemanticsLabel('C, 50 %, en curso, nivel 1 de 5'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('F sostenido, sin datos todavía'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('usa la notación activa en etiquetas y Semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildApp(namingMode: NoteNamingMode.solfege, reduceMotion: true),
      );
      expect(find.text('Do'), findsOneWidget);
      expect(find.text('Sol#'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Do sostenido, 40 %')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('Tab recorre los segmentos en orden cromático y Enter activa', (
      tester,
    ) async {
      final selected = <String>[];
      await tester.pumpWidget(
        buildApp(onSelect: (s) => selected.add(s.note), reduceMotion: true),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(selected, ['C', 'D']);
    });

    testWidgets('con foco, el centro muestra la nota, su nivel y su %', (
      tester,
    ) async {
      NoteProgressSummary? hovered;
      await tester.pumpWidget(
        buildApp(
          onSelect: (_) {},
          onHover: (s) => hovered = s,
          reduceMotion: true,
        ),
      );
      expect(find.text('68 %'), findsOneWidget);
      expect(find.text('Precisión global'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(hovered?.note, 'C#');
      expect(find.text('40 %'), findsOneWidget);
      expect(find.text('C# · nivel 1/5'), findsOneWidget);
      expect(find.text('Precisión global'), findsNothing);
    });

    testWidgets('el toque en un segmento lo selecciona', (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(
        buildApp(onSelect: (s) => selected.add(s.note), reduceMotion: true),
      );

      // Etiqueta de F#: abajo (180°), fuera del anillo.
      await tester.tap(find.text('F#'));
      await tester.pump();
      expect(selected, ['F#']);
    });

    testWidgets('sin onSelect los segmentos no son botones ni enfocables', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildApp(reduceMotion: true));
      final data = tester
          .getSemantics(find.byKey(const ValueKey('ear-map-segment-C')))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('con movimiento reducido no quedan animaciones pendientes', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(reduceMotion: true));
      // Un solo frame: nada queda animando.
      expect(await tester.pumpAndSettle(), 1);
    });

    testWidgets('la entrada escalonada termina', (tester) async {
      await tester.pumpWidget(buildApp());
      final frames = await tester.pumpAndSettle();
      final expected = EarMapWheel.entranceDuration.inMilliseconds ~/ 100;
      expect(frames, greaterThanOrEqualTo(expected));
    });

    testWidgets('variantes oscura y compacta se pintan sin errores', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(theme: AppTheme.dark, onDark: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.session,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: EarMapWheel(summaries: [_summary('A')], compact: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
