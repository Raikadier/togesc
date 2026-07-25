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
    correct: Color(0xFF81C784),
    incorrect: Color(0xFFEF9A9A),
    selection: Color(0xFFFFD54F),
    speedAccent: Color(0xFFFF8A65),
    speedContainer: Color(0xFF3D231C),
    correctContainer: Color(0xFF1B3D24),
    onCorrectContainer: Color(0xFFA5D6A7),
    incorrectContainer: Color(0xFF4E1A1A),
    onIncorrectContainer: Color(0xFFFFB4AB),
    correctDeep: Color(0xFF2E7D32),
    incorrectDeep: Color(0xFFC62828),
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
    );
  }
}
