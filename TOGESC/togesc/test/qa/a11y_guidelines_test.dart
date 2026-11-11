// A11Y · guías automáticas de flutter_test en cada pantalla principal.
//
// - androidTapTargetGuideline (48×48) e iOSTapTargetGuideline (44×44):
//   más estrictas que WCAG 2.5.8 (24×24, AA); se usan como objetivo de
//   producto (DESIGN.md: `touchTargetMin` = 48).
// - labeledTapTargetGuideline: WCAG 4.1.2 (nombre de todo lo pulsable).
// - textContrastGuideline: WCAG 1.4.3 sobre el render real (complementa a
//   `test/helpers/contrast_audit.dart`, que lee los colores del árbol).
//
// Las pantallas de sesión (Juego y Velocidad) llevan siempre
// `AppTheme.session` (oscuro forzado), así que se auditan una sola vez.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_harness.dart';

const _guidelines = <String, AccessibilityGuideline>{
  'android 48dp': androidTapTargetGuideline,
  'iOS 44pt': iOSTapTargetGuideline,
  'etiquetas': labeledTapTargetGuideline,
  'contraste texto': textContrastGuideline,
};

/// Barreras reales destapadas por estas guías (se mantienen como `skip`
/// hasta que se arreglen; el informe las prioriza).
const _known = <String, String>{
  'Juego · fase «Responde»|android 48dp':
      'A11Y: teclas blancas del piano '
      'de sesión de 44,3 px de ancho a 360 px (lib/widgets/piano_keyboard.dart'
      ':588, minWidth 336 + padding no se respeta dentro del layout de la '
      'sesión); WCAG 2.5.8 AA sí se cumple',
};

/// Alto suficiente para que casi todo el contenido entre en pantalla (las
/// guías solo miran lo que está dentro del viewport) a ancho de móvil.
const _size = Size(360, 2000);

void main() {
  for (final screen in a11yScreens) {
    final modes = screen.sessionTheme
        ? const {'sesión': ThemeMode.dark}
        : const {'claro': ThemeMode.light, 'oscuro': ThemeMode.dark};
    for (final mode in modes.entries) {
      group('${screen.name} · ${mode.key}', () {
        for (final g in _guidelines.entries) {
          a11yTestWidgets(g.key, barrier: _known['${screen.name}|${g.key}'], (
            tester,
          ) async {
            final handle = tester.ensureSemantics();
            try {
              await pumpA11yScreen(
                tester,
                screen,
                size: _size,
                mode: mode.value,
                settle: !screen.sessionTheme,
              );
              if (screen.sessionTheme) {
                await pumpFor(tester, const Duration(seconds: 1));
              }
              await expectLater(tester, meetsGuideline(g.value));
            } finally {
              await leaveA11yScreen(tester);
              handle.dispose();
            }
          });
        }
      });
    }
  }

  // Fases con el teclado o el temporizador en pantalla.
  final phases = <String, Future<void> Function(WidgetTester)>{
    'Juego · fase «Responde»': (tester) async {
      await pumpA11yScreen(tester, a11yScreens[1], size: _size, settle: false);
      await pumpFor(tester, const Duration(seconds: 1));
      await startGameSession(tester);
      expect(find.text('RESPONDE'), findsOneWidget);
    },
    'Velocidad · ráfaga en curso': (tester) async {
      await pumpA11yScreen(tester, a11yScreens[3], size: _size, settle: false);
      await pumpFor(tester, const Duration(seconds: 1));
      await startSpeedSession(tester);
      expect(find.byKey(const ValueKey('speed-timer')), findsOneWidget);
    },
  };
  for (final phase in phases.entries) {
    group(phase.key, () {
      for (final g in _guidelines.entries) {
        a11yTestWidgets(g.key, barrier: _known['${phase.key}|${g.key}'], (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          try {
            await phase.value(tester);
            await expectLater(tester, meetsGuideline(g.value));
          } finally {
            await leaveA11yScreen(tester);
            handle.dispose();
          }
        });
      }
    });
  }
}
