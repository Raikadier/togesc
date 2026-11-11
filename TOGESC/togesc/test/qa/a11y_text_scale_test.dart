// A11Y · texto escalado a 360×800 (WCAG 1.4.4 Cambio de tamaño del texto y
// 1.4.10 Reajuste).
//
// - «Texto más grande» de la app (`largeText`, ×1,125; lib/app/
//   large_text_scaler.dart) sobre escalado de sistema 1,0.
// - Escalado de sistema 1,5 y 2,0 (Android/iOS lo ofrecen; 2,0 es el
//   200 % que pide 1.4.4).
//
// Criterio: ningún desborde de layout (`tester.takeException()` nulo). Un
// RenderFlex desbordado recorta texto o lo tapa: el contenido deja de
// estar disponible.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_harness.dart';

class _Scale {
  const _Scale(this.label, this.system, {this.largeText = false});
  final String label;
  final double system;
  final bool largeText;
}

const _scales = [
  _Scale('Texto más grande ×1,125', 1.0, largeText: true),
  _Scale('sistema ×1,5', 1.5),
  _Scale('sistema ×2,0', 2.0),
];

const _size = Size(360, 800);

/// Barreras conocidas: clave `pantalla|escala` → motivo con `ruta:línea`
/// del widget que desborda (salida de `A11Y_RUN_KNOWN=true`).
const _known = <String, String>{};

final _errorDetails = <FlutterErrorDetails>[];

/// Registra los `FlutterErrorDetails` (llevan el widget causante) sin
/// cambiar el manejo de flutter_test. Devuelve la función que lo deshace.
VoidCallback _recordErrors() {
  _errorDetails.clear();
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    _errorDetails.add(details);
    original?.call(details);
  };
  return () => FlutterError.onError = original;
}

/// Falla con la `ruta:línea` de cada widget que desborda.
void expectNoLayoutError(WidgetTester tester) {
  final error = tester.takeException();
  final where = _errorDetails
      .expand((d) => RegExp(r'lib/[\w/]+\.dart:\d+').allMatches(d.toString()))
      .map((m) => m.group(0))
      .toSet()
      .join(', ');
  expect(error, isNull, reason: 'desborde en: $where');
}

void main() {
  for (final screen in a11yScreens) {
    group(screen.name, () {
      for (final scale in _scales) {
        a11yTestWidgets(
          scale.label,
          barrier: _known['${screen.name}|${scale.label}'],
          (tester) async {
            final restore = _recordErrors();
            try {
              await pumpA11yScreen(
                tester,
                screen,
                size: _size,
                textScale: scale.system,
                largeText: scale.largeText,
                settle: false,
              );
              await pumpFor(tester, const Duration(seconds: 2));
              expectNoLayoutError(tester);
            } finally {
              restore();
              await leaveA11yScreen(tester);
            }
          },
        );
      }
    });
  }

  // Estados que no se ven al entrar.
  final states = <String, Future<void> Function(WidgetTester, _Scale)>{
    'Juego · fase «Responde» (teclado)': (tester, scale) async {
      await pumpA11yScreen(
        tester,
        a11yScreens[1],
        size: _size,
        textScale: scale.system,
        largeText: scale.largeText,
        settle: false,
      );
      await pumpFor(tester, const Duration(seconds: 1));
      await startGameSession(tester);
    },
    'Velocidad · ráfaga (temporizador)': (tester, scale) async {
      await pumpA11yScreen(
        tester,
        a11yScreens[3],
        size: _size,
        textScale: scale.system,
        largeText: scale.largeText,
        settle: false,
      );
      await pumpFor(tester, const Duration(seconds: 1));
      await startSpeedSession(tester);
    },
    'Onboarding · pasos 2 a 4': (tester, scale) async {
      await pumpA11yScreen(
        tester,
        a11yScreens.last,
        size: _size,
        textScale: scale.system,
        largeText: scale.largeText,
      );
      // Los desbordes del paso 1 ya los cubre el bloque anterior.
      tester.takeException();
      for (var step = 2; step <= 4; step++) {
        final next = find.byKey(const ValueKey('onboarding-next'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
    },
  };
  const knownStates = <String, String>{};
  for (final state in states.entries) {
    group(state.key, () {
      for (final scale in _scales) {
        a11yTestWidgets(
          scale.label,
          barrier: knownStates['${state.key}|${scale.label}'],
          (tester) async {
            final restore = _recordErrors();
            try {
              await state.value(tester, scale);
              expectNoLayoutError(tester);
            } finally {
              restore();
              await leaveA11yScreen(tester);
            }
          },
        );
      }
    });
  }
}
