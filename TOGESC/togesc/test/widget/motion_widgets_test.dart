import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/app/app_theme.dart';
import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/widgets/count_up_text.dart';
import 'package:togesc/widgets/piano_keyboard.dart';
import 'package:togesc/widgets/session_v2/session_phase.dart';
import 'package:togesc/widgets/session_v2/session_phase_ring.dart';
import 'package:togesc/widgets/staggered_entrance.dart';

Widget _wrap(Widget child, {bool reduceMotion = false, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

String _pct(double v) => '${v.round()} %';

typedef Vector3Like = ({double x, double y});

void main() {
  group('CountUpText', () {
    testWidgets('cuenta de 0 al valor en 900 ms', (tester) async {
      await tester.pumpWidget(
        _wrap(const CountUpText(value: 68, format: _pct)),
      );
      expect(find.text('0 %'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 450));
      final mid = tester.widget<Text>(find.byType(Text)).data!;
      expect(mid, isNot('0 %'));
      expect(mid, isNot('68 %'));

      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text('68 %'), findsOneWidget);
      expect(await tester.pumpAndSettle(), 1);
    });

    testWidgets('con movimiento reducido muestra el valor final', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const CountUpText(value: 68, format: _pct), reduceMotion: true),
      );
      expect(find.text('68 %'), findsOneWidget);
      expect(await tester.pumpAndSettle(), 1);
    });

    testWidgets('el lector lee el valor final, no los intermedios', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const CountUpText(
            value: 68,
            format: _pct,
            semanticsLabel: 'Precisión global, 68 %',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Precisión global, 68 %'), findsOneWidget);
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('StaggeredEntrance', () {
    testWidgets('sube 12 px con fade, retrasada por el índice', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StaggeredEntrance(
            index: 2,
            child: SizedBox(key: ValueKey('block'), width: 10, height: 10),
          ),
        ),
      );
      Opacity opacity() => tester.widget<Opacity>(
        find.ancestor(
          of: find.byKey(const ValueKey('block')),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity().opacity, 0);

      // Durante el retardo (2 × 60 ms) sigue oculto.
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity().opacity, 0);

      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity().opacity, greaterThan(0));

      await tester.pumpAndSettle();
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('con movimiento reducido aparece en su sitio y sin frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StaggeredEntrance(index: 5, child: Text('Bloque')),
          reduceMotion: true,
        ),
      );
      expect(find.text('Bloque'), findsOneWidget);
      expect(find.byType(Opacity), findsNothing);
      expect(await tester.pumpAndSettle(), 1);
    });
  });

  group('PianoKeyboard v2.1 (sesión)', () {
    Widget piano({
      bool large = false,
      PianoKeyboardVariant variant = PianoKeyboardVariant.session,
      Set<String> correct = const {},
      Set<String> wrong = const {},
      bool reduceMotion = false,
    }) {
      return _wrap(
        SizedBox(
          width: 1000,
          child: PianoKeyboard(
            variant: variant,
            large: large,
            correctNotes: correct,
            incorrectNotes: wrong,
            dimOthers: true,
          ),
        ),
        theme: AppTheme.session,
        reduceMotion: reduceMotion,
      );
    }

    double height(WidgetTester tester) => tester
        .getSize(find.byKey(const ValueKey('piano-session-container')))
        .height;

    testWidgets('piano más grande en móvil: 270 de alto y negras de 44×160', (
      tester,
    ) async {
      await tester.pumpWidget(piano(large: true));
      expect(height(tester), DesignTokens.pianoSessionLargeHeight);
      expect(
        tester.getSize(find.byKey(const ValueKey('piano-key-C#'))),
        DesignTokens.pianoSessionLargeBlackKeySize,
      );
    });

    testWidgets('piano más grande en escritorio: 250 y negras de 58×150', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        piano(large: true, variant: PianoKeyboardVariant.sessionWide),
      );
      expect(height(tester), DesignTokens.pianoSessionWideLargeHeight);
      expect(
        tester.getSize(find.byKey(const ValueKey('piano-key-C#'))),
        DesignTokens.pianoSessionWideLargeBlackKeySize,
      );
    });

    testWidgets('sin large conserva las medidas v2', (tester) async {
      await tester.pumpWidget(piano());
      expect(height(tester), DesignTokens.pianoSessionHeight);
    });

    testWidgets('pop y shake al recibir el resultado y luego reposo', (
      tester,
    ) async {
      await tester.pumpWidget(piano());
      await tester.pumpWidget(piano(correct: {'D'}, wrong: {'E'}));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pump(const Duration(milliseconds: 150));
      Iterable<Vector3Like> translationsAbove(String note) => tester
          .widgetList<Transform>(
            find.ancestor(
              of: find.byKey(ValueKey('piano-key-$note')),
              matching: find.byType(Transform),
            ),
          )
          .map((t) => t.transform.getTranslation())
          .map((v) => (x: v.x, y: v.y));

      // D sube (pop) y E se desplaza en horizontal (shake).
      expect(translationsAbove('D').any((v) => v.y < 0), isTrue);
      expect(translationsAbove('E').any((v) => v.x != 0), isTrue);

      await tester.pumpAndSettle();
      expect(translationsAbove('D').every((v) => v.y == 0), isTrue);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('con movimiento reducido el resultado no anima', (
      tester,
    ) async {
      await tester.pumpWidget(piano(reduceMotion: true));
      await tester.pumpWidget(
        piano(correct: {'D'}, wrong: {'E'}, reduceMotion: true),
      );
      // Ni pop/shake ni escala del icono: todo en reposo desde el primer
      // frame. (Material lleva una animación implícita propia, ajena a
      // este widget; en la app la desactiva el TickerMode de TogescApp.)
      final transforms = tester.widgetList<Transform>(
        find.ancestor(
          of: find.byIcon(Icons.check_circle),
          matching: find.byType(Transform),
        ),
      );
      for (final t in transforms) {
        expect(t.transform.getMaxScaleOnAxis(), closeTo(1, 1e-9));
      }
      for (final note in ['D', 'E']) {
        final moved = tester
            .widgetList<Transform>(
              find.ancestor(
                of: find.byKey(ValueKey('piano-key-$note')),
                matching: find.byType(Transform),
              ),
            )
            .where((t) => t.transform.getTranslation().length > 0);
        expect(moved, isEmpty, reason: note);
      }
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('SessionPhaseRing v2.1', () {
    const listenCopy = SessionPhaseCopy(
      overline: 'Escuchando',
      headline: 'Escucha con atención',
      color: DesignTokens.sessionAccent,
    );
    const resultCopy = SessionPhaseCopy(
      overline: 'Correcto',
      headline: 'Era C',
      color: DesignTokens.sessionSuccess,
    );

    Widget ring(SessionPhase phase, {bool reduceMotion = false}) {
      return _wrap(
        SessionPhaseRing(
          phase: phase,
          copy: phase == SessionPhase.result ? resultCopy : listenCopy,
          noteLabel: 'C',
          reduceMotion: reduceMotion,
        ),
        theme: AppTheme.session,
      );
    }

    List<BoxShadow> shadows(WidgetTester tester) {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const ValueKey('session-ring-arc')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (container.decoration! as BoxDecoration).boxShadow ?? const [];
    }

    testWidgets('en result emite un halo de 1,2 s que se apaga', (
      tester,
    ) async {
      await tester.pumpWidget(ring(SessionPhase.answer));
      await tester.pumpWidget(ring(SessionPhase.result));
      await tester.pump(const Duration(milliseconds: 300));
      expect(shadows(tester), isNotEmpty);
      expect(shadows(tester).single.spreadRadius, greaterThan(0));

      await tester.pump(SessionPhaseRing.glowDuration);
      await tester.pump();
      expect(shadows(tester), isEmpty);
    });

    testWidgets('con movimiento reducido no hay arco ni halo', (tester) async {
      await tester.pumpWidget(ring(SessionPhase.answer, reduceMotion: true));
      await tester.pumpWidget(ring(SessionPhase.result, reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(shadows(tester), isEmpty);
    });

    testWidgets('el arco de listen dura 1,5 s', (tester) async {
      await tester.pumpWidget(ring(SessionPhase.answer));
      await tester.pumpWidget(ring(SessionPhase.listen));
      final state = tester.state(find.byType(SessionPhaseRing));
      expect(state, isNotNull);
      await tester.pump(DesignTokens.sessionListenDuration);
      // Las barras de escucha siguen en bucle; el arco ya está lleno.
      expect(tester.takeException(), isNull);
    });
  });
}
