import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/app/app_theme.dart';
import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/app/togesc_colors.dart';

/// Luminancia relativa WCAG 2.x, implementada aparte de
/// `Color.computeLuminance` para validar los tokens de forma independiente.
double _relativeLuminance(Color c) {
  double channel(double v) => v <= 0.03928
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _wcagRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

class _Pair {
  const _Pair(this.label, this.text, this.background, {this.min = 4.5});

  final String label;
  final Color text;
  final Color background;
  final double min;
}

const _white = Color(0xFFFFFFFF);

const _pairs = <_Pair>[
  // --- Claro ---
  _Pair('texto principal / fondo', DesignTokens.textPrimary,
      DesignTokens.background),
  _Pair('texto secundario / fondo', DesignTokens.textSecondary,
      DesignTokens.background),
  _Pair('texto terciario / fondo', DesignTokens.textTertiary,
      DesignTokens.background),
  _Pair('texto terciario / chip', DesignTokens.textTertiary,
      DesignTokens.surfaceContainer),
  _Pair('texto terciario / panel', DesignTokens.textTertiary,
      DesignTokens.surfaceContainerLowest),
  _Pair('texto terciario / nav', DesignTokens.textTertiary,
      DesignTokens.navBar),
  _Pair('nav activa / nav', DesignTokens.primary, DesignTokens.navBar),
  _Pair('primario / fondo', DesignTokens.primary, DesignTokens.background),
  // --- Hero ---
  _Pair('blanco / hero', DesignTokens.onHero, DesignTokens.hero),
  _Pair('overline / hero', DesignTokens.onHeroAccent, DesignTokens.hero),
  _Pair('barra crítica / hero', DesignTokens.criticalBar, DesignTokens.hero,
      min: 3),
  _Pair('barra en curso / hero', DesignTokens.warningBarOnDark,
      DesignTokens.hero, min: 3),
  _Pair('texto CTA / ámbar', DesignTokens.onCtaAmber, DesignTokens.ctaAmber),
  _Pair('aviso / ámbar', DesignTokens.onWarning, DesignTokens.warning),
  _Pair('aviso / ámbar claro', DesignTokens.onWarning,
      DesignTokens.warningLight),
  // --- Sesión oscura ---
  _Pair('sesión principal / bg', DesignTokens.sessionTextPrimary,
      DesignTokens.sessionBackground),
  _Pair('sesión principal / chip', DesignTokens.sessionTextPrimary,
      DesignTokens.sessionChip),
  _Pair('sesión principal / botón', DesignTokens.sessionTextPrimary,
      DesignTokens.sessionButton),
  _Pair('sesión secundario / bg', DesignTokens.sessionTextSecondary,
      DesignTokens.sessionBackground),
  _Pair('sesión secundario / surface', DesignTokens.sessionTextSecondary,
      DesignTokens.sessionSurface),
  _Pair('sesión secundario / chip', DesignTokens.sessionTextSecondary,
      DesignTokens.sessionChip),
  _Pair('sesión secundario / botón', DesignTokens.sessionTextSecondary,
      DesignTokens.sessionButton),
  _Pair('sesión etiqueta / bg', DesignTokens.sessionTextLabel,
      DesignTokens.sessionBackground),
  _Pair('sesión etiqueta / chip', DesignTokens.sessionTextLabel,
      DesignTokens.sessionChip),
  _Pair('acento / bg', DesignTokens.sessionAccent,
      DesignTokens.sessionBackground),
  _Pair('acento / surface', DesignTokens.sessionAccent,
      DesignTokens.sessionSurface),
  _Pair('ámbar fase / bg', DesignTokens.sessionAmber,
      DesignTokens.sessionBackground),
  _Pair('éxito / bg', DesignTokens.sessionSuccess,
      DesignTokens.sessionBackground),
  _Pair('error / bg', DesignTokens.sessionError,
      DesignTokens.sessionBackground),
  _Pair('aviso / bg', DesignTokens.sessionWarning,
      DesignTokens.sessionBackground),
  _Pair('sobre acento', DesignTokens.sessionOnAccent,
      DesignTokens.sessionAccent),
  _Pair('icono rail activo / hero', DesignTokens.sessionAccent,
      DesignTokens.hero),
];

void main() {
  group('masteryColor', () {
    test('49.9 es rojo y 50 es ámbar', () {
      expect(masteryColor(49.9), DesignTokens.masteryRed);
      expect(masteryColor(50), DesignTokens.masteryAmber);
    });

    test('74.9 es ámbar y 75 es verde', () {
      expect(masteryColor(74.9), DesignTokens.masteryAmber);
      expect(masteryColor(75), DesignTokens.masteryGreenLight);
    });

    test('extremos y NaN', () {
      expect(masteryColor(0), DesignTokens.masteryRed);
      expect(masteryColor(100), DesignTokens.masteryGreenLight);
      expect(masteryColor(double.nan), DesignTokens.masteryRed);
    });

    test('el nivel SRS elige el tono de verde', () {
      expect(masteryColor(80, srsLevel: 3), DesignTokens.masteryGreenLight);
      expect(masteryColor(80, srsLevel: 4), DesignTokens.masteryGreen);
      expect(masteryColor(80, srsLevel: 5), DesignTokens.masteryGreenDeep);
      // El nivel no altera rojo ni ámbar.
      expect(masteryColor(40, srsLevel: 5), DesignTokens.masteryRed);
      expect(masteryColor(60, srsLevel: 5), DesignTokens.masteryAmber);
    });

    test('masteryBarColorOnDark respeta los mismos umbrales', () {
      expect(masteryBarColorOnDark(49.9), DesignTokens.criticalBar);
      expect(masteryBarColorOnDark(50), DesignTokens.warningBarOnDark);
      expect(masteryBarColorOnDark(74.9), DesignTokens.warningBarOnDark);
      expect(masteryBarColorOnDark(75), DesignTokens.sessionSuccess);
    });
  });

  group('Contraste WCAG AA', () {
    test('la implementación de referencia da 21:1 y 1:1', () {
      expect(
        _wcagRatio(const Color(0xFF000000), _white),
        closeTo(21, 0.001),
      );
      expect(_wcagRatio(_white, _white), closeTo(1, 0.001));
      // contrastRatio (usado en runtime) coincide con la referencia.
      expect(
        contrastRatio(DesignTokens.textTertiary, DesignTokens.background),
        closeTo(
          _wcagRatio(DesignTokens.textTertiary, DesignTokens.background),
          0.01,
        ),
      );
    });

    for (final pair in _pairs) {
      test('${pair.label} ≥ ${pair.min}:1', () {
        final ratio = _wcagRatio(pair.text, pair.background);
        expect(
          ratio,
          greaterThanOrEqualTo(pair.min),
          reason: '${pair.label}: ${ratio.toStringAsFixed(2)}:1',
        );
      });
    }

    test('el gris v2 original #7F7383 no llegaba a AA (regresión)', () {
      expect(
        _wcagRatio(const Color(0xFF7F7383), DesignTokens.background),
        lessThan(4.5),
      );
    });

    test('texto de cada celda de dominio ≥ 4.5:1', () {
      const cells = [
        ...DesignTokens.masteryRedScale,
        ...DesignTokens.masteryAmberScale,
        ...DesignTokens.masteryGreenScale,
        DesignTokens.masteryEmpty,
      ];
      for (final cell in cells) {
        final text = masteryOnColorFor(cell);
        final ratio = _wcagRatio(text, cell);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'celda $cell con texto $text: ${ratio.toStringAsFixed(2)}',
        );
      }
    });

    test('masteryOnColor cumple AA en los límites de umbral', () {
      for (final pct in [0.0, 49.9, 50.0, 74.9, 75.0, 100.0]) {
        for (final level in [null, 3, 4, 5]) {
          final cell = masteryColor(pct, srsLevel: level);
          final text = masteryOnColor(pct, srsLevel: level);
          expect(
            _wcagRatio(text, cell),
            greaterThanOrEqualTo(4.5),
            reason: 'pct=$pct nivel=$level',
          );
        }
      }
    });

    test('texto blanco no es válido sobre verde claro ni ámbar', () {
      expect(masteryOnColorFor(DesignTokens.masteryGreenLight), isNot(_white));
      expect(masteryOnColorFor(DesignTokens.masteryAmber), isNot(_white));
      expect(
        _wcagRatio(_white, DesignTokens.masteryGreenLight),
        lessThan(4.5),
      );
      expect(_wcagRatio(_white, DesignTokens.masteryAmber), lessThan(4.5));
    });
  });

  group('Tokens v2', () {
    test('valores del spec', () {
      expect(DesignTokens.hero, const Color(0xFF2A0640));
      expect(DesignTokens.sessionBackground, const Color(0xFF141018));
      expect(DesignTokens.sessionSurface, const Color(0xFF1A121E));
      expect(DesignTokens.sessionChip, const Color(0xFF241B2A));
      expect(DesignTokens.sessionButton, const Color(0xFF1E1622));
      expect(DesignTokens.sessionBorder, const Color(0xFF3A2E42));
      expect(DesignTokens.sessionBorderSubtle, const Color(0xFF2E2433));
      expect(DesignTokens.sessionAccent, const Color(0xFFDA9CFF));
      expect(DesignTokens.sessionAmber, const Color(0xFFFFD54F));
    });

    test('radios v2', () {
      expect(DesignTokens.radiusHero, 20);
      expect(DesignTokens.radiusCard, 14);
      expect(DesignTokens.radiusCell, 12);
      expect(DesignTokens.radiusCta, 15);
      expect(DesignTokens.radiusPill, 999);
    });

    test('los números grandes usan cifras tabulares', () {
      const tnum = FontFeature.tabularFigures();
      expect(DesignTokens.bigNumber.fontFeatures, contains(tnum));
      expect(DesignTokens.bigNumberLarge.fontFeatures, contains(tnum));
      expect(DesignTokens.tabularNumbers.fontFeatures, contains(tnum));
    });

    test('gradientes de piano: 2 paradas y extremos del spec', () {
      expect(
        DesignTokens.pianoWhiteKeyGradient.colors,
        const [Color(0xFFFAF6F8), Color(0xFFE4DBE6)],
      );
      expect(
        DesignTokens.pianoBlackKeyCorrectGradient.colors,
        const [Color(0xFF3BA34A), Color(0xFF1B5E20)],
      );
      expect(
        DesignTokens.pianoWhiteKeyWrongGradient.colors,
        const [Color(0xFFF2B4B4), Color(0xFFE08A8A)],
      );
      expect(
        TogescColors.session.pianoBlackKey,
        DesignTokens.pianoBlackKeyGradient,
      );
    });

    test('TogescColors.lerp conserva los gradientes', () {
      final mid = TogescColors.light.lerp(TogescColors.session, 0.5);
      expect(mid.pianoWhiteKey.colors.length, 2);
      expect(mid.correct, isNotNull);
    });
  });

  group('Tokens v2.1', () {
    test('movimiento: valores del SPEC §1.2', () {
      expect(DesignTokens.easeOut, const Cubic(0.22, 1, 0.36, 1));
      expect(DesignTokens.easeSpring, const Cubic(0.34, 1.56, 0.64, 1));
      expect(DesignTokens.durationKey, const Duration(milliseconds: 90));
      expect(DesignTokens.durationFast, const Duration(milliseconds: 120));
      expect(DesignTokens.durationMedium, const Duration(milliseconds: 280));
      expect(DesignTokens.staggerStep, const Duration(milliseconds: 60));
      expect(DesignTokens.staggerWheel, const Duration(milliseconds: 45));
    });

    test('easeSpring rebasa 1 y easeOut no', () {
      final peakSpring = List.generate(
        101,
        (i) => DesignTokens.easeSpring.transform(i / 100),
      ).reduce(math.max);
      final peakOut = List.generate(
        101,
        (i) => DesignTokens.easeOut.transform(i / 100),
      ).reduce(math.max);
      expect(peakSpring, greaterThan(1));
      expect(peakOut, lessThanOrEqualTo(1));
    });

    test('medidas del mapa del oído', () {
      expect(DesignTokens.earMapViewBox, 320);
      expect(DesignTokens.earMapInner, 64);
      expect(DesignTokens.earMapOuter, 126);
      expect(DesignTokens.earMapInnerCompact, 70);
      expect(DesignTokens.earMapOuterCompact, 132);
    });

    test('pista del mapa del oído por tema', () {
      expect(TogescColors.light.earMapTrack, const Color(0xFFF3ECF1));
      expect(TogescColors.dark.earMapTrack, const Color(0xFF241B2A));
      expect(TogescColors.session.earMapTrack, const Color(0xFF241B2A));
      for (final c in [
        TogescColors.light,
        TogescColors.dark,
        TogescColors.session,
      ]) {
        expect(c.earMapTrackOnHero.a, closeTo(0.08, 0.005));
        expect(c.earMapTrackOnHero.withValues(alpha: 1), _white);
      }
    });

    test('la celda vacía en oscuro es #241B2A', () {
      expect(TogescColors.dark.muted, const Color(0xFF241B2A));
      expect(TogescColors.session.muted, const Color(0xFF241B2A));
    });

    test('texto sobre la pista del mapa del oído ≥ 4.5:1', () {
      final onHeroTrack = Color.alphaBlend(
        DesignTokens.earMapTrackOnHero,
        DesignTokens.hero,
      );
      final cases = <(String, Color, Color)>[
        (
          'claro',
          TogescColors.light.textPrimary,
          TogescColors.light.earMapTrack,
        ),
        (
          'oscuro',
          TogescColors.dark.textPrimary,
          TogescColors.dark.earMapTrack,
        ),
        (
          'sesión',
          TogescColors.session.textPrimary,
          TogescColors.session.earMapTrack,
        ),
        ('hero', DesignTokens.onHero, onHeroTrack),
        ('hero acento', DesignTokens.onHeroAccent, onHeroTrack),
      ];
      for (final (label, text, track) in cases) {
        final ratio = _wcagRatio(text, track);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: label);
        expect(contrastRatio(text, track), closeTo(ratio, 0.01), reason: label);
      }
    });
  });

  group('motionDuration', () {
    Future<Duration> resolve(
      WidgetTester tester, {
      required bool reduced,
    }) async {
      late Duration result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Builder(
            builder: (context) {
              result = motionDuration(context, DesignTokens.durationMedium);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('devuelve la duración con movimiento normal', (tester) async {
      expect(
        await resolve(tester, reduced: false),
        DesignTokens.durationMedium,
      );
    });

    testWidgets('devuelve cero con movimiento reducido', (tester) async {
      expect(await resolve(tester, reduced: true), Duration.zero);
    });
  });

  group('AppTheme.session', () {
    testWidgets('es oscuro y usa los tokens de sesión', (tester) async {
      final theme = AppTheme.session;
      await tester.pumpWidget(
        MaterialApp(theme: theme, home: const SizedBox.shrink()),
      );

      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, DesignTokens.sessionBackground);
      expect(theme.colorScheme.primary, DesignTokens.sessionAccent);
      expect(
        theme.colorScheme.onSurfaceVariant,
        DesignTokens.sessionTextSecondary,
      );
      expect(theme.extension<TogescColors>(), TogescColors.session);
      expect(theme.navigationBarTheme.height, DesignTokens.navBarHeight);
    });
  });
}
