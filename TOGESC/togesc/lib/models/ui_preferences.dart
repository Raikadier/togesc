import 'package:flutter/material.dart';

/// Modo de entrada de respuesta en sesion de juego.
enum GameInputMode {
  both('Ambos', 'Piano y campo de texto'),
  pianoOnly('Solo piano', 'Toca las teclas para responder'),
  textOnly('Solo texto', 'Escribe las notas con el teclado');

  const GameInputMode(this.label, this.description);

  final String label;
  final String description;

  static GameInputMode fromId(String? raw) {
    return GameInputMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => GameInputMode.both,
    );
  }
}

/// Preferencia de tema de la aplicacion.
enum AppThemePreference {
  system('Sistema', ThemeMode.system),
  light('Claro', ThemeMode.light),
  dark('Oscuro', ThemeMode.dark);

  const AppThemePreference(this.label, this.themeMode);

  final String label;
  final ThemeMode themeMode;

  static AppThemePreference fromId(String? raw) {
    return AppThemePreference.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AppThemePreference.system,
    );
  }
}

/// Preferencias de UI y accesibilidad (Fase 7D).
class UiPreferences {
  final GameInputMode inputMode;
  final bool confirmBeforeSubmit;
  final bool hidePianoLabels;
  final bool largePiano;
  final bool reduceAnimations;
  final AppThemePreference themePreference;

  const UiPreferences({
    this.inputMode = GameInputMode.both,
    this.confirmBeforeSubmit = true,
    this.hidePianoLabels = false,
    this.largePiano = false,
    this.reduceAnimations = false,
    this.themePreference = AppThemePreference.system,
  });

  UiPreferences copyWith({
    GameInputMode? inputMode,
    bool? confirmBeforeSubmit,
    bool? hidePianoLabels,
    bool? largePiano,
    bool? reduceAnimations,
    AppThemePreference? themePreference,
  }) {
    return UiPreferences(
      inputMode: inputMode ?? this.inputMode,
      confirmBeforeSubmit: confirmBeforeSubmit ?? this.confirmBeforeSubmit,
      hidePianoLabels: hidePianoLabels ?? this.hidePianoLabels,
      largePiano: largePiano ?? this.largePiano,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}
