import 'package:flutter/material.dart';

/// Modo de entrada de respuesta en sesion de juego.
enum GameInputMode {
  both('Ambos', 'Piano principal; texto opcional como alternativa'),
  pianoOnly('Solo piano', 'Toca las teclas para responder'),
  textOnly('Solo texto', 'Escribe las notas con el teclado'),
  humming('Canto / tarareo', 'Experimental: responde cantando o tarareando');

  const GameInputMode(this.label, this.description);

  final String label;
  final String description;

  static GameInputMode fromId(String? raw) {
    return GameInputMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => defaultGameInputMode,
    );
  }
}

/// Modo de entrada por defecto (rediseño v2, D6): solo piano.
/// La entrada por texto sigue disponible como opción en Ajustes.
const GameInputMode defaultGameInputMode = GameInputMode.pianoOnly;

/// Confirmar antes de enviar, por defecto (rediseño v2, D1): un solo toque.
/// Se puede reactivar en Ajustes por accesibilidad.
const bool defaultConfirmBeforeSubmit = false;

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
    this.inputMode = defaultGameInputMode,
    this.confirmBeforeSubmit = defaultConfirmBeforeSubmit,
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
