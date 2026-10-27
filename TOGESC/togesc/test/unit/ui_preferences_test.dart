import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/app/large_text_scaler.dart';
import 'package:togesc/models/ui_preferences.dart';
import 'package:togesc/services/app_preferences.dart';

void main() {
  group('UiPreferences', () {
    test('defaults v2: solo piano y un toque sin confirmar (D1, D6)', () {
      const prefs = UiPreferences();
      expect(prefs.inputMode, GameInputMode.pianoOnly);
      expect(prefs.confirmBeforeSubmit, isFalse);
      expect(prefs.themePreference, AppThemePreference.system);
      expect(prefs.largeText, isFalse);
    });

    test('copyWith cambia largeText y conserva el resto', () {
      const base = UiPreferences(largePiano: true, reduceAnimations: true);
      final changed = base.copyWith(largeText: true);
      expect(changed.largeText, isTrue);
      expect(changed.largePiano, isTrue);
      expect(changed.reduceAnimations, isTrue);
      expect(changed.copyWith().largeText, isTrue);
      expect(changed.copyWith(largeText: false).largeText, isFalse);
    });

    test('GameInputMode.fromId desconocido cae en solo piano', () {
      expect(GameInputMode.fromId(null), GameInputMode.pianoOnly);
      expect(GameInputMode.fromId('xyz'), GameInputMode.pianoOnly);
      expect(GameInputMode.fromId('both'), GameInputMode.both);
      expect(GameInputMode.fromId('textOnly'), GameInputMode.textOnly);
    });

    test('sin nada guardado carga los defaults v2', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      final loaded = prefs.uiPreferences;
      expect(loaded.inputMode, GameInputMode.pianoOnly);
      expect(loaded.confirmBeforeSubmit, isFalse);
      expect(loaded.largeText, isFalse);
    });

    test('migracion: legacy igual al default antiguo recibe el default v2',
        () async {
      SharedPreferences.setMockInitialValues({
        gameInputModeKey: 'both',
        confirmBeforeSubmitKey: true,
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      final loaded = prefs.uiPreferences;
      expect(loaded.inputMode, GameInputMode.pianoOnly);
      expect(loaded.confirmBeforeSubmit, isFalse);
    });

    test('migracion: legacy elegido por el usuario se conserva', () async {
      SharedPreferences.setMockInitialValues({
        gameInputModeKey: 'textOnly',
        confirmBeforeSubmitKey: false,
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      final loaded = prefs.uiPreferences;
      expect(loaded.inputMode, GameInputMode.textOnly);
      expect(loaded.confirmBeforeSubmit, isFalse);
    });

    test('migracion: el valor v2 manda sobre el legacy', () async {
      SharedPreferences.setMockInitialValues({
        gameInputModeKey: 'textOnly',
        gameInputModeV2Key: 'both',
        confirmBeforeSubmitKey: false,
        confirmBeforeSubmitV2Key: true,
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      final loaded = prefs.uiPreferences;
      expect(loaded.inputMode, GameInputMode.both);
      expect(loaded.confirmBeforeSubmit, isTrue);
    });

    test('reactivar confirmar tras migrar persiste en v2', () async {
      SharedPreferences.setMockInitialValues({confirmBeforeSubmitKey: true});
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(prefs.uiPreferences.confirmBeforeSubmit, isFalse);

      await prefs.setUiPreferences(
        prefs.uiPreferences.copyWith(confirmBeforeSubmit: true),
      );
      expect(prefs.uiPreferences.confirmBeforeSubmit, isTrue);
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
          largeText: true,
          themePreference: AppThemePreference.dark,
        ),
      );

      final loaded = prefs.uiPreferences;
      expect(loaded.inputMode, GameInputMode.pianoOnly);
      expect(loaded.confirmBeforeSubmit, isFalse);
      expect(loaded.hidePianoLabels, isTrue);
      expect(loaded.largePiano, isTrue);
      expect(loaded.reduceAnimations, isTrue);
      expect(loaded.largeText, isTrue);
      expect(store.getBool(largeTextKey), isTrue);
      expect(loaded.themePreference, AppThemePreference.dark);
    });
  });

  group('applyLargeText', () {
    test('desactivado devuelve el escalado del sistema tal cual', () {
      const system = TextScaler.linear(1.3);
      expect(applyLargeText(system, largeText: false), same(system));
    });

    test('activado multiplica por 1,125 encima del sistema', () {
      expect(
        applyLargeText(TextScaler.noScaling, largeText: true).scale(16),
        closeTo(18, 1e-9),
      );
      expect(
        applyLargeText(const TextScaler.linear(1.3), largeText: true).scale(16),
        closeTo(16 * 1.3 * largeTextScaleFactor, 1e-9),
      );
    });

    test('respeta un escalado del sistema no lineal', () {
      final clamped = const TextScaler.linear(3).clamp(maxScaleFactor: 2);
      expect(
        applyLargeText(clamped, largeText: true).scale(10),
        closeTo(10 * 2 * largeTextScaleFactor, 1e-9),
      );
    });
  });

  group('DesignTokens dark', () {
    test('define fondo Harmonic Precision oscuro', () {
      expect(DesignTokens.darkBackground, const Color(0xFF141018));
    });
  });
}
