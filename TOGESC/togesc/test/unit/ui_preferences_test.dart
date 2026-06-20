import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/models/ui_preferences.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  group('UiPreferences', () {
    test('defaults conservan comportamiento previo', () {
      const prefs = UiPreferences();
      expect(prefs.inputMode, GameInputMode.both);
      expect(prefs.confirmBeforeSubmit, isTrue);
      expect(prefs.themePreference, AppThemePreference.system);
    });

    test('persistencia en AppPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await SharedPreferences.getInstance();
      final prefs = AppPreferences(store);

      await prefs.setUiPreferences(
        const UiPreferences(
          inputMode: GameInputMode.pianoOnly,
          confirmBeforeSubmit: false,
          hidePianoLabels: true,
          largePiano: true,
          reduceAnimations: true,
          themePreference: AppThemePreference.dark,
        ),
      );

      final loaded = prefs.uiPreferences;
      expect(loaded.inputMode, GameInputMode.pianoOnly);
      expect(loaded.confirmBeforeSubmit, isFalse);
      expect(loaded.hidePianoLabels, isTrue);
      expect(loaded.largePiano, isTrue);
      expect(loaded.reduceAnimations, isTrue);
      expect(loaded.themePreference, AppThemePreference.dark);
    });
  });

  group('DesignTokens dark', () {
    test('define fondo Harmonic Precision oscuro', () {
      expect(DesignTokens.darkBackground, const Color(0xFF141018));
    });
  });
}
