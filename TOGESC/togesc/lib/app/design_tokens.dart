import 'package:flutter/material.dart';

/// Tokens del design system Harmonic Precision (Stitch / Material 3).
abstract final class DesignTokens {
  // --- Marca y superficies ---
  static const Color background = Color(0xFFFFF7FC);
  static const Color onBackground = Color(0xFF1E1B1E);
  static const Color surface = Color(0xFFFFF7FC);
  static const Color onSurface = Color(0xFF1E1B1E);
  static const Color onSurfaceVariant = Color(0xFF4D4351);
  static const Color surfaceContainerLow = Color(0xFFF9F1F6);
  static const Color surfaceContainer = Color(0xFFF3ECF1);
  static const Color surfaceContainerHigh = Color(0xFFEEE6EB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  /// Contorno y texto terciario/etiquetas.
  ///
  /// v2 especifica `#7F7383`, pero sobre `background` da 4,26:1 y sobre
  /// `surfaceContainer` 3,86:1 (no AA para 12–13 px). Se oscurece solo la
  /// luminosidad (mismo tono HSL) a `#726876`: 5,04:1 sobre `#FFF7FC`,
  /// 4,57:1 sobre `#F3ECF1` y 5,31:1 sobre `#FFFFFF`. Muchos widgets usan
  /// `colorScheme.outline` como color de texto, así que el ajuste los cubre.
  static const Color outline = Color(0xFF726876);
  static const Color outlineVariant = Color(0xFFD0C2D3);

  // --- Primarios ---
  static const Color primary = Color(0xFF4E0078);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF6A1B9A);
  static const Color onPrimaryContainer = Color(0xFFDA9CFF);

  // --- Secundarios ---
  static const Color secondary = Color(0xFF9A25AE);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFED76FD);
  static const Color onSecondaryContainer = Color(0xFF69007A);

  // --- Terciarios ---
  static const Color tertiary = Color(0xFF402747);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF573D5F);
  static const Color onTertiaryContainer = Color(0xFFCBAAD2);

  // --- Error ---
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // --- Feedback musical (semánticos Stitch) ---
  static const Color correct = Color(0xFF2E7D32);
  static const Color incorrect = Color(0xFFC62828);
  static const Color selection = Color(0xFFFFB300);

  // --- Piano ---
  static const Color pianoWhite = Color(0xFFFFFFFF);
  static const Color pianoBlack = Color(0xFF212121);

  // --- Tema oscuro Harmonic Precision ---
  static const Color darkBackground = Color(0xFF141018);
  static const Color darkOnBackground = Color(0xFFECE0E8);
  static const Color darkSurface = Color(0xFF141018);
  static const Color darkOnSurface = Color(0xFFECE0E8);
  static const Color darkOnSurfaceVariant = Color(0xFFCFC3CD);
  static const Color darkSurfaceContainerLow = Color(0xFF1E1622);
  static const Color darkSurfaceContainer = Color(0xFF281F2C);
  static const Color darkSurfaceContainerLowest = Color(0xFF1A121E);
  static const Color darkOutline = Color(0xFF988E98);
  static const Color darkOutlineVariant = Color(0xFF4D4351);
  static const Color darkPrimary = Color(0xFFDA9CFF);
  static const Color darkOnPrimary = Color(0xFF4E0078);
  static const Color darkPrimaryContainer = Color(0xFF6A1B9A);
  static const Color darkOnPrimaryContainer = Color(0xFFF3D4FF);

  // --- Forma y espaciado ---
  static const double radiusMd = 12;
  static const double shellBreakpoint = 600;
  static const double contentMaxWidth = 1200;
  static const double touchTargetMin = 48;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double marginMobile = 16;
  static const double marginDesktop = 24;

  /// Motion canónico (Operate). Honrar reduceAnimations vía MediaQuery.
  static const Duration motionFast = Duration(milliseconds: 120);
  static const Duration motionMedium = Duration(milliseconds: 280);
  static const Duration motionKeyPress = Duration(milliseconds: 90);

  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);

  // --- Modo velocidad ---
  /// Acento de velocidad en claro. v2 no cubre velocidad y el `#E64A19`
  /// original no llegaba a AA (3,9:1 con blanco encima y 3,7:1 como texto
  /// sobre `background`). Se usa el mismo tono más profundo: blanco encima
  /// 5,6:1, como texto 5,3:1 sobre `background` y 4,9:1 sobre
  /// `speedContainer`.
  static const Color speedAccent = Color(0xFFBF360C);
  static const Color speedContainer = Color(0xFFFFEBE6);

  /// Acento de velocidad en oscuro y en la sesión: 8,1:1 sobre
  /// `sessionBackground` y 7,6:1 con `hero` encima.
  static const Color speedAccentOnDark = Color(0xFFFF8A65);

  // ===========================================================================
  // Rediseño v2 «La sesión como instrumento»
  // (docs/design_v2/SPEC_rediseno_v2.md). Ratios WCAG 2.x calculados con la
  // luminancia relativa; los verifica test/unit/design_tokens_v2_test.dart.
  // ===========================================================================

  // --- v2 · Claro ---
  /// Card hero de Home y KPI «Pendientes». Blanco encima: 17,5:1;
  /// `onHeroAccent` (#DA9CFF) encima: 8,5:1.
  static const Color hero = Color(0xFF2A0640);
  static const Color onHero = Color(0xFFFFFFFF);
  static const Color onHeroAccent = Color(0xFFDA9CFF);

  /// CTA ámbar de Home. Texto `onCtaAmber` (#2A0640): 9,8:1.
  /// Nunca texto blanco encima (1,8:1).
  static const Color ctaAmber = Color(0xFFFFB300);
  static const Color onCtaAmber = Color(0xFF2A0640);

  /// Aviso claro. Texto `onWarning` (#3A2B00): 7,7:1 sobre #FFB300 y
  /// 9,0:1 sobre #FFC94D.
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFC94D);
  static const Color onWarning = Color(0xFF3A2B00);

  /// Barra de precisión crítica (<50 %) sobre el hero: 7,7:1.
  static const Color criticalBar = Color(0xFFFF8A8A);

  /// Barra de precisión en curso (50–74 %) sobre el hero: 11,2:1.
  /// Es también el aviso del modo oscuro.
  static const Color warningBarOnDark = Color(0xFFFFC46B);

  /// Barra de nav. inferior (borde superior = `divider`).
  static const Color navBar = Color(0xFFFFFDFE);
  static const Color divider = Color(0xFFEEE6EB);

  /// Textos claros v2. Sobre `background`: principal 16,2:1,
  /// secundario 8,9:1 y terciario 5,0:1 (ver `outline`).
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textTertiary = outline;

  /// Marca PRO.
  static const Color pro = Color(0xFF9A25AE);

  // --- v2 · Sesión oscura (forzada en `AppTheme.session`) ---
  static const Color sessionBackground = Color(0xFF141018);

  /// Panel del teclado y del enfoque SRS.
  static const Color sessionSurface = Color(0xFF1A121E);

  /// Chips de la barra superior; también divisor y borde del rail.
  static const Color sessionChip = Color(0xFF241B2A);

  /// Botón secundario (borde `sessionBorder`).
  static const Color sessionButton = Color(0xFF1E1622);
  static const Color sessionBorder = Color(0xFF3A2E42);
  static const Color sessionBorderSubtle = Color(0xFF2E2433);
  static const Color sessionDivider = sessionChip;

  /// Texto principal: 14,7:1 sobre bg y 13,0:1 sobre chip.
  static const Color sessionTextPrimary = Color(0xFFECE0E8);

  /// Texto secundario: 6,2:1 sobre bg, 6,0:1 sobre surface, 5,4:1 sobre
  /// chip y 5,8:1 sobre botón.
  static const Color sessionTextSecondary = Color(0xFF9C8FA3);

  /// Texto terciario / etiquetas: 11,1:1 sobre bg y 9,8:1 sobre chip.
  static const Color sessionTextLabel = Color(0xFFCFC3CD);

  /// Acento de sesión («Escuchando», barra de progreso): 9,1:1 sobre bg.
  static const Color sessionAccent = Color(0xFFDA9CFF);

  /// Ámbar de fase «Responde»: 13,3:1 sobre bg.
  static const Color sessionAmber = Color(0xFFFFD54F);

  /// Éxito «Correcto»: 9,3:1 sobre bg.
  static const Color sessionSuccess = Color(0xFF81C784);

  /// Error «Incorrecto»: 8,7:1 sobre bg.
  static const Color sessionError = Color(0xFFEF9A9A);

  /// Aviso en oscuro: 12,0:1 sobre bg.
  static const Color sessionWarning = warningBarOnDark;

  /// Texto sobre los rellenos claros de sesión (acento, ámbar, éxito,
  /// error): ≥8,5:1 en todos los casos.
  static const Color sessionOnAccent = hero;

  // --- v2 · Rejilla de dominio (de claro a profundo) ---
  /// Rojo (<50 %). Texto: `#1E1B1E` sobre #FF8A8A (7,5:1) y blanco sobre
  /// #C62828 (5,6:1).
  static const Color masteryRedLight = criticalBar;
  static const Color masteryRed = Color(0xFFC62828);
  static const List<Color> masteryRedScale = [masteryRedLight, masteryRed];

  /// Ámbar (50–74 %). Texto `onWarning` #3A2B00: 9,0:1 y 7,7:1.
  static const Color masteryAmberLight = warningLight;
  static const Color masteryAmber = Color(0xFFFFB300);
  static const List<Color> masteryAmberScale = [masteryAmberLight, masteryAmber];

  /// Verde (≥75 %), por nivel SRS 3 / 4 / 5.
  /// - #4E9A52 + texto `#1E1B1E`: 4,9:1 (blanco daría 3,5:1).
  /// - #38853C + texto blanco: 4,6:1. v2 pide #3B8C3F, pero ni blanco
  ///   (4,2:1) ni `#1E1B1E` (4,1:1) llegan a AA; se oscurece la luminosidad
  ///   un 3 % manteniendo el tono.
  /// - #2E7D32 + texto blanco: 5,1:1.
  static const Color masteryGreenLight = Color(0xFF4E9A52);
  static const Color masteryGreen = Color(0xFF38853C);
  static const Color masteryGreenDeep = Color(0xFF2E7D32);
  static const List<Color> masteryGreenScale = [
    masteryGreenLight,
    masteryGreen,
    masteryGreenDeep,
  ];

  /// Celda sin datos (y día sin práctica en la semana L–D).
  static const Color masteryEmpty = surfaceContainer;

  /// Umbrales de dominio (porcentaje 0–100).
  static const double masteryAmberThreshold = 50;
  static const double masteryGreenThreshold = 75;

  /// Meta de precisión global de Progreso.
  static const double accuracyGoalPercent = 90;

  // --- v2 · Teclado de sesión (gradientes verticales) ---
  static const LinearGradient pianoWhiteKeyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFAF6F8), Color(0xFFE4DBE6)],
  );
  static const LinearGradient pianoBlackKeyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A2230), Color(0xFF17121B)],
  );
  static const LinearGradient pianoWhiteKeyCorrectGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFA5D6A7), Color(0xFF6FBF73)],
  );
  static const LinearGradient pianoBlackKeyCorrectGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3BA34A), Color(0xFF1B5E20)],
  );
  static const LinearGradient pianoWhiteKeyWrongGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF2B4B4), Color(0xFFE08A8A)],
  );
  static const LinearGradient pianoBlackKeyWrongGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFC0504F), Color(0xFF7A1010)],
  );

  /// Opacidad de las teclas atenuadas (sin feedback) en `result`.
  static const double pianoDimAlpha = 0.45;

  /// Teclas atenuadas: el gradiente en reposo al 45 % sobre
  /// `sessionSurface`, precompuesto para no usar `Opacity`.
  static const LinearGradient pianoWhiteKeyDimmedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7F7980), Color(0xFF756C78)],
  );
  static const LinearGradient pianoBlackKeyDimmedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF211926), Color(0xFF19121D)],
  );

  /// Contenedor del teclado de sesión.
  static const Color pianoSessionContainer = sessionSurface;
  static const double pianoSessionHeight = 230;
  static const double pianoSessionWideHeight = 210;
  static const double pianoSessionRadius = 16;
  static const Size pianoSessionBlackKeySize = Size(38, 140);
  static const Size pianoSessionWideBlackKeySize = Size(52, 126);

  // --- v2 · Forma ---
  static const double radiusHero = 20;
  static const double radiusCard = 14;
  static const double radiusCell = 12;
  static const double radiusCta = 15;
  static const double radiusPill = 999;

  static BorderRadius get borderRadiusHero => BorderRadius.circular(radiusHero);
  static BorderRadius get borderRadiusCard => BorderRadius.circular(radiusCard);
  static BorderRadius get borderRadiusCell => BorderRadius.circular(radiusCell);
  static BorderRadius get borderRadiusCta => BorderRadius.circular(radiusCta);
  static BorderRadius get borderRadiusPill => BorderRadius.circular(radiusPill);

  // --- v2 · Medidas ---
  static const double appBarHeight = 56;
  static const double navBarHeight = 76;
  static const double railWidth = 76;
  static const double ctaHeight = 58;
  static const double desktopBreakpoint = 1024;
  static const double sessionProgressBarHeight = 3;
  static const double sessionRingSize = 150;
  static const double sessionRingSizeDesktop = 170;
  static const double sessionSrsPanelWidth = 300;

  // --- v2 · Tiempos de sesión ---
  static const Duration sessionListenDuration = Duration(milliseconds: 1500);
  static const Duration sessionResultDuration = Duration(milliseconds: 2200);

  /// Avance tras `result` con movimiento reducido.
  static const Duration sessionResultDurationReduced = Duration(
    milliseconds: 400,
  );

  // --- v2 · Tipografía ---
  // Sin `fontFamily`: heredan Hanken Grotesk del tema vía DefaultTextStyle
  // (`inherit: true`). Sin color: se aplica con `copyWith(color: …)`.

  /// Overline 12/700, ls 1.5. Flutter no tiene `text-transform`: pasa el
  /// texto con `.toUpperCase()`.
  static const TextStyle overline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    letterSpacing: 1.5,
  );

  /// Overline 13/700, ls 1.6 (fase de sesión, cabeceras de sección).
  static const TextStyle overlineLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 18 / 13,
    letterSpacing: 1.6,
  );

  /// Logo «TOGESC» 15/800, ls 2.4.
  static const TextStyle logo = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.4,
  );

  /// Número grande 44/800 con cifras tabulares («12» rondas del hero).
  static const TextStyle bigNumber = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.32,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Número grande 52/800 con cifras tabulares («Precisión global»).
  static const TextStyle bigNumberLarge = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.56,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Cifras tabulares sin cambiar tamaño (chips «3 / 12», «78 %», tablas):
  /// `style.merge(DesignTokens.tabularNumbers)`.
  static const TextStyle tabularNumbers = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Color de la celda de dominio para un porcentaje de precisión (0–100).
///
/// Umbrales v2: `< 50` rojo, `50 ≤ pct < 75` ámbar y `≥ 75` verde. Dentro del
/// verde, [srsLevel] (0–5) elige el tono: ≤3 o `null` → claro, 4 → medio y
/// 5 → profundo. `NaN` cuenta como rojo. Función pura.
Color masteryColor(double pct, {int? srsLevel}) {
  if (pct.isNaN || pct < DesignTokens.masteryAmberThreshold) {
    return DesignTokens.masteryRed;
  }
  if (pct < DesignTokens.masteryGreenThreshold) {
    return DesignTokens.masteryAmber;
  }
  if (srsLevel == null || srsLevel <= 3) return DesignTokens.masteryGreenLight;
  if (srsLevel == 4) return DesignTokens.masteryGreen;
  return DesignTokens.masteryGreenDeep;
}

/// Texto AA (≥4,5:1) sobre [masteryColor] con los mismos argumentos.
Color masteryOnColor(double pct, {int? srsLevel}) {
  return masteryOnColorFor(masteryColor(pct, srsLevel: srsLevel));
}

/// Texto AA para cualquier color de las escalas de dominio. Para otros
/// colores elige entre `onSurface` y blanco el de mayor contraste.
Color masteryOnColorFor(Color cell) {
  if (cell == DesignTokens.masteryRed ||
      cell == DesignTokens.masteryGreen ||
      cell == DesignTokens.masteryGreenDeep) {
    return const Color(0xFFFFFFFF);
  }
  if (cell == DesignTokens.masteryAmber ||
      cell == DesignTokens.masteryAmberLight) {
    return DesignTokens.onWarning;
  }
  if (cell == DesignTokens.masteryRedLight ||
      cell == DesignTokens.masteryGreenLight ||
      cell == DesignTokens.masteryEmpty) {
    return DesignTokens.onSurface;
  }
  return contrastRatio(DesignTokens.onSurface, cell) >=
          contrastRatio(const Color(0xFFFFFFFF), cell)
      ? DesignTokens.onSurface
      : const Color(0xFFFFFFFF);
}

/// Color de la barra de precisión de 3 px sobre fondos oscuros (hero de Home,
/// sesión). `< 50` #FF8A8A, `50–74` #FFC46B y `≥ 75` #81C784.
Color masteryBarColorOnDark(double pct) {
  if (pct.isNaN || pct < DesignTokens.masteryAmberThreshold) {
    return DesignTokens.criticalBar;
  }
  if (pct < DesignTokens.masteryGreenThreshold) {
    return DesignTokens.warningBarOnDark;
  }
  return DesignTokens.sessionSuccess;
}

/// Ratio de contraste WCAG 2.x entre dos colores opacos (1–21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
