import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ui_preferences.dart';
import 'app_preferences_provider.dart';

final uiPreferencesProvider =
    AsyncNotifierProvider<UiPreferencesNotifier, UiPreferences>(
  UiPreferencesNotifier.new,
);

class UiPreferencesNotifier extends AsyncNotifier<UiPreferences> {
  @override
  Future<UiPreferences> build() async {
    final prefs = await ref.watch(appPreferencesProvider.future);
    return prefs.uiPreferences;
  }

  Future<void> save(UiPreferences value) async {
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setUiPreferences(value);
    state = AsyncData(value);
  }

  Future<void> setInputMode(GameInputMode mode) async {
    await save((state.valueOrNull ?? const UiPreferences()).copyWith(
      inputMode: mode,
    ));
  }

  Future<void> setConfirmBeforeSubmit(bool value) async {
    await save((state.valueOrNull ?? const UiPreferences()).copyWith(
      confirmBeforeSubmit: value,
    ));
  }

  Future<void> setHidePianoLabels(bool value) async {
    await save((state.valueOrNull ?? const UiPreferences()).copyWith(
      hidePianoLabels: value,
    ));
  }

  Future<void> setLargePiano(bool value) async {
    await save((state.valueOrNull ?? const UiPreferences()).copyWith(
      largePiano: value,
    ));
  }

  Future<void> setReduceAnimations(bool value) async {
    await save((state.valueOrNull ?? const UiPreferences()).copyWith(
      reduceAnimations: value,
    ));
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    await save((state.valueOrNull ?? const UiPreferences()).copyWith(
      themePreference: preference,
    ));
  }
}

/// Atajo sincrono para widgets que necesitan ThemeMode.
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(uiPreferencesProvider).valueOrNull?.themePreference.themeMode ??
      ThemeMode.system;
});
