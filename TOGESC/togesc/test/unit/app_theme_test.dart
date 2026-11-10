import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:togesc/app/app_theme.dart';
import 'package:togesc/app/design_tokens.dart';
import 'package:togesc/app/togesc_colors.dart';

void main() {
  group('DesignTokens', () {
    test('primaryContainer matches marca Stitch', () {
      expect(DesignTokens.primaryContainer, const Color(0xFF6A1B9A));
    });

    test('background matches Harmonic Precision', () {
      expect(DesignTokens.background, const Color(0xFFFFF7FC));
    });

    test('feedback colors match piano semantics', () {
      expect(DesignTokens.correct, const Color(0xFF2E7D32));
      expect(DesignTokens.incorrect, const Color(0xFFC62828));
      expect(DesignTokens.selection, const Color(0xFFFFB300));
    });

    test('touch target and radius match design system', () {
      expect(DesignTokens.touchTargetMin, 48);
      expect(DesignTokens.radiusMd, 12);
    });
  });

  group('TogescColors · superficies v2 del shell', () {
    void expectAA(TogescColors c, String theme) {
      final pairs = <(String, Color, Color)>[
        ('marca / página', c.brand, c.page),
        ('marca / nav', c.brand, c.navBar),
        ('marca / tile', c.brand, c.tile),
        ('principal / página', c.textPrimary, c.page),
        ('principal / tile', c.textPrimary, c.tile),
        ('principal / apagada', c.textPrimary, c.muted),
        ('secundario / página', c.textSecondary, c.page),
        ('secundario / nav', c.textSecondary, c.navBar),
        ('secundario / tile', c.textSecondary, c.tile),
        ('secundario / apagada', c.textSecondary, c.muted),
        ('terciario / página', c.textTertiary, c.page),
        ('terciario / tile', c.textTertiary, c.tile),
        ('terciario / apagada', c.textTertiary, c.muted),
      ];
      for (final (label, fg, bg) in pairs) {
        expect(
          contrastRatio(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$theme · $label',
        );
      }
      // Icono Pro (no texto): ≥3:1 sobre página y tile.
      expect(contrastRatio(c.proAccent, c.page), greaterThanOrEqualTo(3));
      expect(contrastRatio(c.proAccent, c.tile), greaterThanOrEqualTo(3));
    }

    test('claro conserva los tokens v2', () {
      const c = TogescColors.light;
      expect(c.brand, DesignTokens.primary);
      expect(c.page, DesignTokens.background);
      expect(c.navBar, DesignTokens.navBar);
      expect(c.tile, DesignTokens.surfaceContainerLowest);
      expect(c.muted, DesignTokens.masteryEmpty);
      expect(c.cardBorder, DesignTokens.outlineVariant);
      expectAA(c, 'claro');
    });

    test('oscuro toma la paleta de sesión', () {
      const c = TogescColors.dark;
      expect(c.page, const Color(0xFF141018));
      expect(c.navBar, const Color(0xFF1A121E));
      expect(c.tile, const Color(0xFF1A121E));
      expect(c.muted, const Color(0xFF241B2A));
      expect(c.cardBorder, const Color(0xFF3A2E42));
      expect(c.textPrimary, const Color(0xFFECE0E8));
      expect(c.textSecondary, const Color(0xFF9C8FA3));
      expect(c.brand, const Color(0xFFDA9CFF));
      expectAA(c, 'oscuro');
    });

    testWidgets('AppTheme registra la extensión de cada tema', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      expect(
        AppTheme.light.extension<TogescColors>()!.page,
        AppTheme.light.scaffoldBackgroundColor,
      );
      expect(
        AppTheme.dark.extension<TogescColors>()!.page,
        AppTheme.dark.scaffoldBackgroundColor,
      );
      expect(
        AppTheme.dark.extension<TogescColors>()!.muted,
        AppTheme.dark.colorScheme.surfaceContainer,
      );
      expect(
        AppTheme.dark.extension<TogescColors>()!.cardBorder,
        AppTheme.dark.colorScheme.outlineVariant,
      );
    });

    testWidgets('error del tema oscuro es legible (AA) sobre el fondo', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final dark = AppTheme.dark;
      expect(
        contrastRatio(dark.colorScheme.error, dark.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(dark.colorScheme.onError, dark.colorScheme.error),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('logo «TOGESC» con AA en ambos temas', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final c = theme.extension<TogescColors>()!;
        expect(
          contrastRatio(c.brand, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });
}
