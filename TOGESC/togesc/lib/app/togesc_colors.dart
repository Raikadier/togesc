import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Colores semanticos de producto (feedback musical y modo velocidad).
///
/// Se registran como [ThemeExtension] para que light/dark resuelvan el
/// contraste correcto sin hardcodear tokens claros sobre superficies oscuras.
@immutable
class TogescColors extends ThemeExtension<TogescColors> {
  const TogescColors({
    required this.correct,
    required this.incorrect,
    required this.selection,
    required this.speedAccent,
    required this.speedContainer,
    required this.correctContainer,
    required this.onCorrectContainer,
    required this.incorrectContainer,
    required this.onIncorrectContainer,
    required this.correctDeep,
    required this.incorrectDeep,
    required this.selectionDeep,
    this.onSpeedAccent = DesignTokens.onPrimary,
    this.brand = DesignTokens.primary,
    this.page = DesignTokens.background,
    this.navBar = DesignTokens.navBar,
    this.divider = DesignTokens.divider,
    this.tile = DesignTokens.surfaceContainerLowest,
    this.muted = DesignTokens.surfaceContainer,
    this.cardBorder = DesignTokens.outlineVariant,
    this.textPrimary = DesignTokens.textPrimary,
    this.textSecondary = DesignTokens.textSecondary,
    this.textTertiary = DesignTokens.textTertiary,
    this.proAccent = DesignTokens.pro,
    this.earMapTrack = DesignTokens.surfaceContainer,
    this.earMapTrackOnHero = DesignTokens.earMapTrackOnHero,
    this.pianoWhiteKey = DesignTokens.pianoWhiteKeyGradient,
    this.pianoBlackKey = DesignTokens.pianoBlackKeyGradient,
    this.pianoWhiteKeyCorrect = DesignTokens.pianoWhiteKeyCorrectGradient,
    this.pianoBlackKeyCorrect = DesignTokens.pianoBlackKeyCorrectGradient,
    this.pianoWhiteKeyWrong = DesignTokens.pianoWhiteKeyWrongGradient,
    this.pianoBlackKeyWrong = DesignTokens.pianoBlackKeyWrongGradient,
    this.pianoWhiteKeyDimmed = DesignTokens.pianoWhiteKeyDimmedGradient,
    this.pianoBlackKeyDimmed = DesignTokens.pianoBlackKeyDimmedGradient,
  });

  final Color correct;
  final Color incorrect;
  final Color selection;
  final Color speedAccent;
  final Color speedContainer;
  final Color correctContainer;
  final Color onCorrectContainer;
  final Color incorrectContainer;
  final Color onIncorrectContainer;

  /// Extremo oscuro de gradientes (teclas negras / acentos).
  final Color correctDeep;
  final Color incorrectDeep;
  final Color selectionDeep;

  /// Texto e iconos sobre un relleno [speedAccent] (≥5,6:1 en los tres
  /// temas): blanco en claro y `hero` en oscuro y sesión.
  final Color onSpeedAccent;

  // --- Superficies v2 del shell (Home, Progreso, Perfil, nav) ---
  /// Marca sobre superficies del shell (logo, nav activa, iconos, «Ver todos»). Claro #4E0078; oscuro #DA9CFF (≥9:1 sobre #141018).
  final Color brand;

  /// Fondo de página de las pantallas v2 del shell.
  final Color page;

  /// Fondo de la barra inferior y del rail.
  final Color navBar;

  /// Separadores y borde de la barra/rail.
  final Color divider;

  /// Relleno de tiles y paneles (práctica libre, KPI, listas).
  final Color tile;

  /// Relleno apagado: pistas de barras, chips, celdas sin datos (dominio y semana).
  final Color muted;

  /// Borde de tiles y paneles.
  final Color cardBorder;

  /// Texto principal sobre `page`, `tile` y `muted`.
  final Color textPrimary;

  /// Texto secundario (AA sobre `page`, `tile` y `muted`).
  final Color textSecondary;

  /// Texto terciario y overlines (AA sobre `page`, `tile` y `muted`).
  final Color textTertiary;

  /// Icono Pro sobre superficie (candados). El relleno de la insignia PRO sigue siendo `DesignTokens.pro`.
  final Color proAccent;

  /// Pista (sector vacío) del mapa del oído. Claro #F3ECF1; oscuro y sesión #241B2A.
  final Color earMapTrack;

  /// Pista del mapa del oído sobre la card `hero` (blanco al 8 %, igual en todos los temas).
  final Color earMapTrackOnHero;

  /// Gradientes del teclado v2 (iguales en claro, oscuro y sesión).
  /// Reposo, correcta, errónea y atenuada, para teclas blancas y negras.
  final LinearGradient pianoWhiteKey;
  final LinearGradient pianoBlackKey;
  final LinearGradient pianoWhiteKeyCorrect;
  final LinearGradient pianoBlackKeyCorrect;
  final LinearGradient pianoWhiteKeyWrong;
  final LinearGradient pianoBlackKeyWrong;
  final LinearGradient pianoWhiteKeyDimmed;
  final LinearGradient pianoBlackKeyDimmed;

  static TogescColors of(BuildContext context) {
    // Fallback light para tests/widgets sin AppTheme; la app registra la extension.
    return Theme.of(context).extension<TogescColors>() ?? light;
  }

  static const light = TogescColors(
    correct: DesignTokens.correct,
    incorrect: DesignTokens.incorrect,
    selection: DesignTokens.selection,
    speedAccent: DesignTokens.speedAccent,
    speedContainer: DesignTokens.speedContainer,
    correctContainer: Color(0xFFE8F5E9),
    onCorrectContainer: Color(0xFF1B5E20),
    incorrectContainer: DesignTokens.errorContainer,
    onIncorrectContainer: DesignTokens.incorrect,
    correctDeep: Color(0xFF1B5E20),
    incorrectDeep: Color(0xFF8B0000),
    selectionDeep: Color(0xFF5D4800),
  );

  /// Variantes iluminadas para contraste AA sobre `#141018`.
  static const dark = TogescColors(
    brand: DesignTokens.darkPrimary,
    page: DesignTokens.darkBackground,
    navBar: DesignTokens.sessionSurface,
    divider: DesignTokens.sessionBorder,
    tile: DesignTokens.sessionSurface,
    muted: DesignTokens.sessionChip,
    cardBorder: DesignTokens.sessionBorder,
    textPrimary: DesignTokens.sessionTextPrimary,
    textSecondary: DesignTokens.sessionTextSecondary,
    textTertiary: DesignTokens.sessionTextSecondary,
    proAccent: DesignTokens.secondaryContainer,
    earMapTrack: DesignTokens.sessionChip,
    correct: Color(0xFF81C784),
    incorrect: Color(0xFFEF9A9A),
    selection: Color(0xFFFFD54F),
    speedAccent: DesignTokens.speedAccentOnDark,
    onSpeedAccent: DesignTokens.hero,
    speedContainer: Color(0xFF3D231C),
    correctContainer: Color(0xFF1B3D24),
    onCorrectContainer: Color(0xFFA5D6A7),
    incorrectContainer: Color(0xFF4E1A1A),
    onIncorrectContainer: Color(0xFFFFB4AB),
    correctDeep: Color(0xFF2E7D32),
    incorrectDeep: Color(0xFFC62828),
    selectionDeep: Color(0xFF8A6A00),
  );

  /// Sesión v2 oscura forzada (`AppTheme.session`). Feedback del spec:
  /// éxito #81C784, error #EF9A9A y ámbar de fase #FFD54F, todos ≥8,7:1
  /// sobre `#141018`.
  static const session = TogescColors(
    brand: DesignTokens.darkPrimary,
    page: DesignTokens.sessionBackground,
    navBar: DesignTokens.sessionBackground,
    divider: DesignTokens.sessionChip,
    tile: DesignTokens.sessionSurface,
    muted: DesignTokens.sessionChip,
    cardBorder: DesignTokens.sessionBorder,
    textPrimary: DesignTokens.sessionTextPrimary,
    textSecondary: DesignTokens.sessionTextSecondary,
    textTertiary: DesignTokens.sessionTextSecondary,
    proAccent: DesignTokens.secondaryContainer,
    earMapTrack: DesignTokens.sessionChip,
    correct: DesignTokens.sessionSuccess,
    incorrect: DesignTokens.sessionError,
    selection: DesignTokens.sessionAmber,
    speedAccent: DesignTokens.speedAccentOnDark,
    onSpeedAccent: DesignTokens.hero,
    speedContainer: Color(0xFF3D231C),
    correctContainer: Color(0xFF1B3D24),
    onCorrectContainer: Color(0xFFA5D6A7),
    incorrectContainer: Color(0xFF4E1A1A),
    onIncorrectContainer: Color(0xFFFFB4AB),
    correctDeep: Color(0xFF1B5E20),
    incorrectDeep: Color(0xFF7A1010),
    selectionDeep: Color(0xFF8A6A00),
  );

  @override
  TogescColors copyWith({
    Color? correct,
    Color? incorrect,
    Color? selection,
    Color? speedAccent,
    Color? speedContainer,
    Color? correctContainer,
    Color? onCorrectContainer,
    Color? incorrectContainer,
    Color? onIncorrectContainer,
    Color? correctDeep,
    Color? incorrectDeep,
    Color? selectionDeep,
    Color? onSpeedAccent,
    Color? brand,
    Color? page,
    Color? navBar,
    Color? divider,
    Color? tile,
    Color? muted,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? proAccent,
    Color? earMapTrack,
    Color? earMapTrackOnHero,
    LinearGradient? pianoWhiteKey,
    LinearGradient? pianoBlackKey,
    LinearGradient? pianoWhiteKeyCorrect,
    LinearGradient? pianoBlackKeyCorrect,
    LinearGradient? pianoWhiteKeyWrong,
    LinearGradient? pianoBlackKeyWrong,
    LinearGradient? pianoWhiteKeyDimmed,
    LinearGradient? pianoBlackKeyDimmed,
  }) {
    return TogescColors(
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      selection: selection ?? this.selection,
      speedAccent: speedAccent ?? this.speedAccent,
      speedContainer: speedContainer ?? this.speedContainer,
      correctContainer: correctContainer ?? this.correctContainer,
      onCorrectContainer: onCorrectContainer ?? this.onCorrectContainer,
      incorrectContainer: incorrectContainer ?? this.incorrectContainer,
      onIncorrectContainer: onIncorrectContainer ?? this.onIncorrectContainer,
      correctDeep: correctDeep ?? this.correctDeep,
      incorrectDeep: incorrectDeep ?? this.incorrectDeep,
      selectionDeep: selectionDeep ?? this.selectionDeep,
      onSpeedAccent: onSpeedAccent ?? this.onSpeedAccent,
      brand: brand ?? this.brand,
      page: page ?? this.page,
      navBar: navBar ?? this.navBar,
      divider: divider ?? this.divider,
      tile: tile ?? this.tile,
      muted: muted ?? this.muted,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      proAccent: proAccent ?? this.proAccent,
      earMapTrack: earMapTrack ?? this.earMapTrack,
      earMapTrackOnHero: earMapTrackOnHero ?? this.earMapTrackOnHero,
      pianoWhiteKey: pianoWhiteKey ?? this.pianoWhiteKey,
      pianoBlackKey: pianoBlackKey ?? this.pianoBlackKey,
      pianoWhiteKeyCorrect: pianoWhiteKeyCorrect ?? this.pianoWhiteKeyCorrect,
      pianoBlackKeyCorrect: pianoBlackKeyCorrect ?? this.pianoBlackKeyCorrect,
      pianoWhiteKeyWrong: pianoWhiteKeyWrong ?? this.pianoWhiteKeyWrong,
      pianoBlackKeyWrong: pianoBlackKeyWrong ?? this.pianoBlackKeyWrong,
      pianoWhiteKeyDimmed: pianoWhiteKeyDimmed ?? this.pianoWhiteKeyDimmed,
      pianoBlackKeyDimmed: pianoBlackKeyDimmed ?? this.pianoBlackKeyDimmed,
    );
  }

  @override
  TogescColors lerp(ThemeExtension<TogescColors>? other, double t) {
    if (other is! TogescColors) return this;
    return TogescColors(
      correct: Color.lerp(correct, other.correct, t)!,
      incorrect: Color.lerp(incorrect, other.incorrect, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
      speedAccent: Color.lerp(speedAccent, other.speedAccent, t)!,
      speedContainer: Color.lerp(speedContainer, other.speedContainer, t)!,
      correctContainer: Color.lerp(
        correctContainer,
        other.correctContainer,
        t,
      )!,
      onCorrectContainer: Color.lerp(
        onCorrectContainer,
        other.onCorrectContainer,
        t,
      )!,
      incorrectContainer: Color.lerp(
        incorrectContainer,
        other.incorrectContainer,
        t,
      )!,
      onIncorrectContainer: Color.lerp(
        onIncorrectContainer,
        other.onIncorrectContainer,
        t,
      )!,
      correctDeep: Color.lerp(correctDeep, other.correctDeep, t)!,
      incorrectDeep: Color.lerp(incorrectDeep, other.incorrectDeep, t)!,
      selectionDeep: Color.lerp(selectionDeep, other.selectionDeep, t)!,
      onSpeedAccent: Color.lerp(onSpeedAccent, other.onSpeedAccent, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      page: Color.lerp(page, other.page, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      tile: Color.lerp(tile, other.tile, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      proAccent: Color.lerp(proAccent, other.proAccent, t)!,
      earMapTrack: Color.lerp(earMapTrack, other.earMapTrack, t)!,
      earMapTrackOnHero: Color.lerp(
        earMapTrackOnHero,
        other.earMapTrackOnHero,
        t,
      )!,
      pianoWhiteKey: LinearGradient.lerp(
        pianoWhiteKey,
        other.pianoWhiteKey,
        t,
      )!,
      pianoBlackKey: LinearGradient.lerp(
        pianoBlackKey,
        other.pianoBlackKey,
        t,
      )!,
      pianoWhiteKeyCorrect: LinearGradient.lerp(
        pianoWhiteKeyCorrect,
        other.pianoWhiteKeyCorrect,
        t,
      )!,
      pianoBlackKeyCorrect: LinearGradient.lerp(
        pianoBlackKeyCorrect,
        other.pianoBlackKeyCorrect,
        t,
      )!,
      pianoWhiteKeyWrong: LinearGradient.lerp(
        pianoWhiteKeyWrong,
        other.pianoWhiteKeyWrong,
        t,
      )!,
      pianoBlackKeyWrong: LinearGradient.lerp(
        pianoBlackKeyWrong,
        other.pianoBlackKeyWrong,
        t,
      )!,
      pianoWhiteKeyDimmed: LinearGradient.lerp(
        pianoWhiteKeyDimmed,
        other.pianoWhiteKeyDimmed,
        t,
      )!,
      pianoBlackKeyDimmed: LinearGradient.lerp(
        pianoBlackKeyDimmed,
        other.pianoBlackKeyDimmed,
        t,
      )!,
    );
  }
}
