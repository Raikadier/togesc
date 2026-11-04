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
const _known = <String, String>{
  'Home|sistema ×1,5': _home,
  'Home|sistema ×2,0': _home,
  'Velocidad (selector)|sistema ×1,5': _speedSelect,
  'Velocidad (selector)|sistema ×2,0': _speedSelect,
  'Velocidad (sesión)|sistema ×2,0': _speedIdle,
  'Estadísticas|Texto más grande ×1,125': _stats,
  'Estadísticas|sistema ×1,5': _stats,
  'Estadísticas|sistema ×2,0': _stats,
  'Progreso por nota|sistema ×2,0':
      'A11Y: filas etiqueta/valor del detalle '
      'SRS desbordan (lib/widgets/note_srs_detail_card.dart:147)',
  'Onboarding|sistema ×1,5': _onboarding,
  'Onboarding|sistema ×2,0': _onboarding,
};

const _home =
    'A11Y: Home desborda: leyenda del mapa del oído '
    '(lib/widgets/home_v2/ear_map_card.dart:197, y :106 a ×2,0; hasta '
    '163 px), celda de la semana de alto fijo 44 '
    '(lib/widgets/home_v2/week_strip.dart:110, desborda en :121) y cabecera '
    'de la tile de práctica libre (lib/widgets/home_v2/free_practice_tiles'
    '.dart:114)';
const _speedSelect =
    'A11Y: selector de Velocidad desborda en las tarjetas '
    'de dificultad (lib/widgets/speed_mode_select_views.dart:168) y en la '
    'fila del CTA (lib/widgets/speed_session_views.dart:567)';
const _speedIdle =
    'A11Y: «Listo para el desafío» desborda 86 px en '
    'vertical a ×2,0 (lib/widgets/game_session_views.dart:58, Column '
    'centrada sin scroll)';
const _stats =
    'A11Y: las pestañas «Resumen/Historial» son una Row sin '
    'ajuste (lib/widgets/progress_v2/progress_tabs.dart:81; minWidth 112 '
    'por pestaña) y desbordan ya con «Texto más grande»; a ×1,5 también la '
    'cabecera de dominio (lib/widgets/progress_v2/mastery_overview.dart:97)';
const _onboarding =
    'A11Y: cabecera del onboarding (logo + «Saltar») '
    'desborda a la derecha (lib/screens/onboarding_screen.dart:88); a ×2,0 '
    'también el paso (lib/widgets/onboarding_views.dart:100)';

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
  const keyActions =
      'A11Y: fila «Repetir / Saltar» de la sesión sin '
      'ajuste (lib/widgets/session_v2/session_key_actions.dart:29)';
  const knownStates = <String, String>{
    'Juego · fase «Responde» (teclado)|sistema ×1,5': keyActions,
    'Juego · fase «Responde» (teclado)|sistema ×2,0': keyActions,
    'Velocidad · ráfaga (temporizador)|sistema ×1,5':
        'A11Y: barra de '
        'estadísticas de la ráfaga desborda 43 px (lib/widgets/togesc_ui.dart'
        ':183, Row spaceAround sin ajuste)',
    'Velocidad · ráfaga (temporizador)|sistema ×2,0':
        'A11Y: la ráfaga '
        'desborda 86 px en vertical (lib/widgets/game_session_views.dart:58)',
    'Onboarding · pasos 2 a 4|sistema ×2,0': _onboarding,
  };
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
