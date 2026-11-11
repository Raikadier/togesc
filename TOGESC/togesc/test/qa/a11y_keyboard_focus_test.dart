// A11Y · teclado y foco visible.
//
// - WCAG 2.1.1 Teclado y 2.4.3 Orden del foco: Tab recorre los controles
//   principales de cada pantalla en orden de lectura y sin paradas dobles.
// - WCAG 2.4.7 Foco visible (AA): al enfocar un control cambia lo que se
//   pinta en su zona.
// - SPEC v2.1 §1.3: «anillo de 3 px en `primary` (claro) o #DA9CFF
//   (oscuro), con 2 px de separación, en todo lo enfocable». Se mide en
//   píxeles: la banda entre 2 y 5 px por fuera del control debe cambiar
//   al enfocarlo.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/app/design_tokens.dart' show contrastRatio;

import 'a11y_harness.dart';

const _size = Size(400, 1600);

/// Clave `ValueKey<String>` más cercana al nodo con foco.
String? _focusedKey() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  String? key;
  final own = context.widget.key;
  if (own is ValueKey<String>) return own.value;
  context.visitAncestorElements((e) {
    final k = e.widget.key;
    if (k is ValueKey<String>) key = k.value;
    return key == null;
  });
  return key;
}

Rect? _focusedRect() => FocusManager.instance.primaryFocus?.rect;

/// Pulsa Tab [count] veces y devuelve la clave y el nodo de cada parada.
Future<List<(String?, FocusNode?)>> _tabStops(
  WidgetTester tester,
  int count,
) async {
  final stops = <(String?, FocusNode?)>[];
  for (var i = 0; i < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 50));
    stops.add((_focusedKey(), FocusManager.instance.primaryFocus));
  }
  return stops;
}

/// Parada doble: dos paradas seguidas en nodos anidados (el mismo control
/// enfocado dos veces).
void _expectNoNestedStops(List<(String?, FocusNode?)> stops) {
  for (var i = 1; i < stops.length; i++) {
    final a = stops[i - 1].$2;
    final b = stops[i].$2;
    if (a == null || b == null || a == b) continue;
    final nested = b.ancestors.contains(a) || a.ancestors.contains(b);
    expect(
      nested,
      isFalse,
      reason:
          'paradas ${i - 1} y $i (${stops[i].$1}) son el mismo '
          'control: ${a.rect} / ${b.rect}',
    );
  }
}

/// Pulsa Tab hasta que el foco cae en [key] (o en un descendiente).
Future<Rect> _tabTo(WidgetTester tester, String key, {int max = 60}) async {
  for (var i = 0; i < max; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 50));
    if (_focusedKey() == key) return _focusedRect()!;
  }
  fail('Tab no llega a «$key» en $max pulsaciones');
}

/// Comprueba que [expected] aparece, en ese orden, entre las paradas.
void _expectSubsequence(List<String?> stops, List<String> expected) {
  var i = 0;
  for (final s in stops) {
    if (i < expected.length && s == expected[i]) i++;
  }
  expect(
    i,
    expected.length,
    reason: 'orden esperado $expected; paradas reales $stops',
  );
}

class _Frame {
  _Frame(this.bytes, this.width);
  final ByteData bytes;
  final int width;

  int pixel(int x, int y) => bytes.getUint32((y * width + x) * 4);

  Color color(int x, int y) {
    final o = (y * width + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(o + 3),
      bytes.getUint8(o),
      bytes.getUint8(o + 1),
      bytes.getUint8(o + 2),
    );
  }
}

/// Píxeles en `rect.inflate(5)` cuyo color con foco contrasta ≥ 3:1 con
/// el color sin foco (WCAG 1.4.11 aplicado al indicador de foco).
int _highContrastChanges(_Frame idle, _Frame focused, Rect rect) {
  final area = rect.inflate(5);
  final maxY = idle.bytes.lengthInBytes ~/ (idle.width * 4) - 1;
  var count = 0;
  for (var y = area.top.floor(); y <= area.bottom.ceil(); y++) {
    for (var x = area.left.floor(); x <= area.right.ceil(); x++) {
      if (x < 0 || y < 0 || x >= idle.width || y > maxY) continue;
      if (idle.pixel(x, y) == focused.pixel(x, y)) continue;
      if (contrastRatio(idle.color(x, y), focused.color(x, y)) >= 3) count++;
    }
  }
  return count;
}

Future<_Frame> _capture(WidgetTester tester) async {
  final element = tester.binding.rootElement!;
  final image = (await tester.runAsync(() => captureImage(element)))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final frame = _Frame(bytes, image.width);
  image.dispose();
  return frame;
}

/// Fracción de píxeles que cambian entre [a] y [b] en `rect.inflate(outer)`.
/// Con [inner] solo se cuenta la banda entre `inner` y `outer` px por fuera
/// de [rect].
double _changedFraction(
  _Frame a,
  _Frame b,
  Rect rect, {
  double? inner,
  required double outer,
}) {
  final bandOuter = rect.inflate(outer);
  final bandInner = inner == null ? null : rect.inflate(inner);
  var total = 0;
  var changed = 0;
  final maxX = a.width - 1;
  final maxY = a.bytes.lengthInBytes ~/ (a.width * 4) - 1;
  for (var y = bandOuter.top.floor(); y <= bandOuter.bottom.ceil(); y++) {
    for (var x = bandOuter.left.floor(); x <= bandOuter.right.ceil(); x++) {
      if (x < 0 || y < 0 || x > maxX || y > maxY) continue;
      final p = Offset(x + 0.5, y + 0.5);
      if (bandInner != null && bandInner.contains(p)) continue;
      total++;
      if (a.pixel(x, y) != b.pixel(x, y)) changed++;
    }
  }
  return total == 0 ? 0 : changed / total;
}

class _FocusTarget {
  const _FocusTarget(this.screen, this.key, this.what);
  final A11yScreen screen;
  final String key;
  final String what;
}

void main() {
  group('orden de Tab', () {
    const expected = <String, List<String>>{
      'Home': [
        'today-start-cta',
        'today-adjust-link',
        'home-see-all-modes',
        'free-tile-singleNote',
        'ear-map-open-progress',
      ],
      'Juego': ['session-instrument', 'session-start', 'session-test-sound'],
      'Velocidad (selector)': [
        'speed-diff-easy',
        'speed-diff-pro',
        'speed-diff-elite',
        'nav-practice',
      ],
      'Estadísticas': ['progress-tabs', 'nav-practice'],
      'Perfil/Cuenta': ['account-pro-entry', 'account-export', 'nav-practice'],
      'Ajustes': [
        'settings-a11y',
        'settings-large-text',
        'settings-large-piano',
        'settings-hide-labels',
      ],
      'Paywall': ['paywall-panel', 'nav-practice'],
      'Onboarding': ['onboarding-skip', 'onboarding-next'],
    };
    for (final screen in a11yScreens) {
      final keys = expected[screen.name];
      if (keys == null) continue;
      testWidgets(screen.name, (tester) async {
        try {
          await pumpA11yScreen(tester, screen, size: _size, settle: false);
          await pumpFor(tester, const Duration(seconds: 2));
          final stops = await _tabStops(tester, 25);
          _expectSubsequence([for (final s in stops) s.$1], keys);
        } finally {
          await leaveA11yScreen(tester);
        }
      });
    }

    testWidgets('Velocidad (sesión): Tab llega a «Comenzar»', (tester) async {
      try {
        await pumpA11yScreen(
          tester,
          a11yScreens[3],
          size: _size,
          settle: false,
        );
        await pumpFor(tester, const Duration(seconds: 1));
        var reached = false;
        for (var i = 0; i < 6 && !reached; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump(const Duration(milliseconds: 50));
          final ctx = FocusManager.instance.primaryFocus?.context;
          reached =
              ctx != null &&
              find
                  .descendant(
                    of: find.byElementPredicate((e) => e == ctx),
                    matching: find.text('Comenzar'),
                  )
                  .evaluate()
                  .isNotEmpty;
        }
        expect(reached, isTrue);
      } finally {
        await leaveA11yScreen(tester);
      }
    });
  });

  group('sin paradas dobles', () {
    a11yTestWidgets('Juego · piano en «Responde»', (tester) async {
      try {
        await pumpA11yScreen(
          tester,
          a11yScreens[1],
          size: _size,
          settle: false,
        );
        await pumpFor(tester, const Duration(seconds: 1));
        await startGameSession(tester);
        _expectNoNestedStops(await _tabStops(tester, 20));
      } finally {
        await leaveA11yScreen(tester);
      }
    });
    for (final screen in a11yScreens) {
      if (screen.sessionTheme) continue;
      a11yTestWidgets(screen.name, (tester) async {
        try {
          await pumpA11yScreen(tester, screen, size: _size, settle: false);
          await pumpFor(tester, const Duration(seconds: 2));
          _expectNoNestedStops(await _tabStops(tester, 25));
        } finally {
          await leaveA11yScreen(tester);
        }
      });
    }
  });

  group('foco visible', () {
    final targets = [
      _FocusTarget(a11yScreens[0], 'today-start-cta', 'CTA «Empezar sesión»'),
      _FocusTarget(a11yScreens[0], 'free-tile-singleNote', 'tile de práctica'),
      _FocusTarget(a11yScreens[0], 'ear-map-segment-C', 'segmento del mapa'),
      _FocusTarget(a11yScreens[0], 'nav-practice', 'barra inferior'),
      _FocusTarget(a11yScreens[4], 'progress-tabs', 'pestaña «Resumen»'),
      _FocusTarget(
        a11yScreens[7],
        'settings-large-text',
        'interruptor «Texto más grande»',
      ),
      _FocusTarget(a11yScreens[9], 'onboarding-next', 'botón «Siguiente»'),
    ];
    for (final t in targets) {
      group('${t.screen.name} · ${t.what}', () {
        Future<(_Frame, _Frame, Rect)> focusAndCapture(
          WidgetTester tester,
        ) async {
          await pumpA11yScreen(tester, t.screen, size: _size, settle: false);
          await pumpFor(tester, const Duration(seconds: 2));
          final rect = await _tabTo(tester, t.key);
          await tester.pumpAndSettle();
          final focused = await _capture(tester);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final idle = await _capture(tester);
          return (idle, focused, rect);
        }

        testWidgets('WCAG 2.4.7: el foco cambia lo pintado', (tester) async {
          try {
            final (idle, focused, rect) = await focusAndCapture(tester);
            final changed = _changedFraction(idle, focused, rect, outer: 5);
            // Con un velo de foco (≈10 % de opacidad) cambia casi todo el
            // fondo del control; con nada, 0.
            expect(changed, greaterThan(0.05));
          } finally {
            await leaveA11yScreen(tester);
          }
        });

        a11yTestWidgets(
          'WCAG 1.4.11: el indicador contrasta ≥ 3:1 (≥ 1 px de perímetro)',
          (tester) async {
            try {
              final (idle, focused, rect) = await focusAndCapture(tester);
              final perimeter = (2 * (rect.width + rect.height)).round();
              expect(
                _highContrastChanges(idle, focused, rect),
                greaterThanOrEqualTo(perimeter),
                reason:
                    'píxeles con cambio ≥ 3:1 frente a un perímetro de '
                    '$perimeter px',
              );
            } finally {
              await leaveA11yScreen(tester);
            }
          },
        );

        a11yTestWidgets('SPEC §1.3: anillo de 3 px a 2 px del control', (
          tester,
        ) async {
          try {
            final (idle, focused, rect) = await focusAndCapture(tester);
            final ring = _changedFraction(
              idle,
              focused,
              rect,
              inner: 2,
              outer: 5,
            );
            expect(
              ring,
              greaterThan(0.6),
              reason: 'banda 2–5 px fuera de $rect',
            );
          } finally {
            await leaveA11yScreen(tester);
          }
        });
      });
    }
  });
}
