// A11Y · movimiento reducido (WCAG 2.3.3 Animación desde interacciones,
// AAA; 2.2.2 Pausar, detener, ocultar, A, para lo que se mueve solo).
//
// SPEC v2.1 §1.2: con `MediaQuery.disableAnimations` o la preferencia
// `reduceAnimations`, «la duración pasa a 0 y no hay escalonado».
//
// Criterio: se muestrea `hasRunningAnimations` cada 50 ms y ninguna racha
// continua de animación puede superar 250 ms. Se toleran así los fundidos
// de color de 200 ms que Material aplica por su cuenta (`AnimatedTheme`,
// `AnimatedDefaultTextStyle` de los botones), que no son movimiento; lo
// que el SPEC prohíbe (count-up de 900 ms, escalonados, pulsos, anillos)
// da rachas largas. Las pruebas de control demuestran que, sin la opción,
// el muestreo sí las detecta.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_harness.dart';

const _step = 50;
const _maxStreakMs = 250;

/// Racha más larga (ms) con animaciones en curso durante [total].
Future<int> _longestAnimationStreak(
  WidgetTester tester, {
  Duration total = const Duration(milliseconds: 2000),
}) async {
  var longest = 0;
  var current = 0;
  for (var ms = 0; ms <= total.inMilliseconds; ms += _step) {
    if (tester.hasRunningAnimations) {
      current += _step;
      if (current > longest) longest = current;
    } else {
      current = 0;
    }
    await tester.pump(const Duration(milliseconds: _step));
  }
  return longest;
}

void main() {
  for (final pref in const {
    'sistema (disableAnimations)': false,
    'app (reduceAnimations)': true,
  }.entries) {
    group('movimiento reducido · ${pref.key}', () {
      for (final screen in a11yScreens) {
        testWidgets(screen.name, (tester) async {
          try {
            await pumpA11yScreen(
              tester,
              screen,
              disableAnimations: !pref.value,
              reduceAnimations: pref.value,
              settle: false,
            );
            expect(
              await _longestAnimationStreak(tester),
              lessThanOrEqualTo(_maxStreakMs),
            );
          } finally {
            await leaveA11yScreen(tester);
          }
        });
      }

      a11yTestWidgets('Juego · «Estoy listo», «Responde» y respuesta', (
        tester,
      ) async {
        try {
          await pumpA11yScreen(
            tester,
            a11yScreens[1],
            disableAnimations: !pref.value,
            reduceAnimations: pref.value,
            settle: false,
          );
          await pumpFor(tester, const Duration(milliseconds: 500));
          await startGameSession(tester);
          expect(find.text('RESPONDE'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('piano-key-C')));
          expect(
            await _longestAnimationStreak(tester),
            lessThanOrEqualTo(_maxStreakMs),
          );
        } finally {
          await leaveA11yScreen(tester);
        }
      });

      testWidgets('Velocidad · cuenta atrás y ráfaga', (tester) async {
        try {
          await pumpA11yScreen(
            tester,
            a11yScreens[3],
            disableAnimations: !pref.value,
            reduceAnimations: pref.value,
            settle: false,
          );
          await pumpFor(tester, const Duration(milliseconds: 500));
          await tester.tap(find.text('Comenzar'));
          expect(
            await _longestAnimationStreak(
              tester,
              total: const Duration(seconds: 4),
            ),
            lessThanOrEqualTo(_maxStreakMs),
          );
        } finally {
          await leaveA11yScreen(tester);
        }
      });
    });
  }

  group('navegación con movimiento reducido', () {
    for (final pref in const {
      'sistema (disableAnimations)': false,
      'app (reduceAnimations)': true,
    }.entries) {
      a11yTestWidgets(
        'Home → Juego: la página nueva se ve entera · ${pref.key}',
        (tester) async {
          try {
            await pumpA11yScreen(
              tester,
              a11yScreens[0],
              size: const Size(400, 1600),
              disableAnimations: !pref.value,
              reduceAnimations: pref.value,
              settle: false,
            );
            await pumpFor(tester, const Duration(seconds: 1));
            await tester.tap(find.byKey(const ValueKey('today-start-cta')));
            await pumpFor(tester, const Duration(seconds: 2));
            final title = find.text('PREPARADO');
            expect(title, findsOneWidget);
            final transitions = <String>[];
            tester.element(title).visitAncestorElements((a) {
              final w = a.widget;
              if (w is FadeTransition && w.opacity.value < 1) {
                transitions.add('Fade(${w.opacity.value})');
              }
              if (w is SlideTransition && w.position.value != Offset.zero) {
                transitions.add('Slide(${w.position.value})');
              }
              return true;
            });
            expect(transitions, isEmpty);
            // Centrado en 400 px de ancho, como sin la opción.
            expect(tester.getCenter(title).dx, closeTo(200, 1));
          } finally {
            await leaveA11yScreen(tester);
          }
        },
      );
    }
  });

  group('control (sin movimiento reducido el muestreo sí detecta)', () {
    // Home (rueda y entrada escalonada) y Onboarding (ecualizador). Progreso
    // dejó de servir de control: sin intentos ya no pinta la rueda.
    for (final screen in [a11yScreens[0], a11yScreens.last]) {
      testWidgets(screen.name, (tester) async {
        try {
          await pumpA11yScreen(tester, screen, settle: false);
          expect(
            await _longestAnimationStreak(tester),
            greaterThan(_maxStreakMs),
          );
        } finally {
          await leaveA11yScreen(tester);
        }
      });
    }
  });
}
