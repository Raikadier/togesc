import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// Tema visual TOGESC — Harmonic Precision (Material 3 + Hanken Grotesk).
abstract final class AppTheme {
  static const Color seedColor = DesignTokens.primaryContainer;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: DesignTokens.primaryContainer,
      brightness: Brightness.light,
    ).copyWith(
      primary: DesignTokens.primary,
      onPrimary: DesignTokens.onPrimary,
      primaryContainer: DesignTokens.primaryContainer,
      onPrimaryContainer: DesignTokens.onPrimaryContainer,
      secondary: DesignTokens.secondary,
      onSecondary: DesignTokens.onSecondary,
      secondaryContainer: DesignTokens.secondaryContainer,
      onSecondaryContainer: DesignTokens.onSecondaryContainer,
      tertiary: DesignTokens.tertiary,
      onTertiary: DesignTokens.onTertiary,
      tertiaryContainer: DesignTokens.tertiaryContainer,
      onTertiaryContainer: DesignTokens.onTertiaryContainer,
      error: DesignTokens.error,
      onError: DesignTokens.onError,
      errorContainer: DesignTokens.errorContainer,
      onErrorContainer: DesignTokens.onErrorContainer,
      surface: DesignTokens.surface,
      onSurface: DesignTokens.onSurface,
      onSurfaceVariant: DesignTokens.onSurfaceVariant,
      outline: DesignTokens.outline,
      outlineVariant: DesignTokens.outlineVariant,
      surfaceContainerHighest: const Color(0xFFE8E0E5),
      surfaceContainerHigh: const Color(0xFFEEE6EB),
      surfaceContainer: DesignTokens.surfaceContainer,
      surfaceContainerLow: DesignTokens.surfaceContainerLow,
      surfaceContainerLowest: const Color(0xFFFFFFFF),
    );

    final textTheme = _textTheme(Brightness.light);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: DesignTokens.background,
      useMaterial3: true,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: DesignTokens.background,
        foregroundColor: DesignTokens.onSurface,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: DesignTokens.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: DesignTokens.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          side: const BorderSide(color: DesignTokens.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DesignTokens.primaryContainer,
          foregroundColor: DesignTokens.onPrimary,
          minimumSize: const Size(DesignTokens.touchTargetMin, DesignTokens.touchTargetMin),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.primaryContainer,
          minimumSize: const Size(DesignTokens.touchTargetMin, DesignTokens.touchTargetMin),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
          side: const BorderSide(color: DesignTokens.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLg,
          vertical: DesignTokens.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          borderSide: const BorderSide(color: DesignTokens.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          borderSide: const BorderSide(color: DesignTokens.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          borderSide: const BorderSide(
            color: DesignTokens.primaryContainer,
            width: 2,
          ),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: DesignTokens.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.surfaceContainerLow,
        selectedColor: DesignTokens.primaryContainer.withValues(alpha: 0.15),
        labelStyle: textTheme.labelLarge,
        side: const BorderSide(color: DesignTokens.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSm,
          vertical: DesignTokens.spacingXs,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DesignTokens.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
        ),
        elevation: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DesignTokens.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          side: const BorderSide(color: DesignTokens.outlineVariant),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final textTheme = _textTheme(Brightness.dark);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(DesignTokens.touchTargetMin, DesignTokens.touchTargetMin),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMd,
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final hanken = GoogleFonts.hankenGroteskTextTheme(base);

    return hanken.copyWith(
      headlineLarge: hanken.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.56,
      ),
      headlineMedium: hanken.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      ),
      titleLarge: hanken.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      ),
      bodyLarge: hanken.bodyLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 26 / 18,
      ),
      bodyMedium: hanken.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      labelLarge: hanken.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        letterSpacing: 0.1,
      ),
      labelMedium: hanken.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.5,
      ),
    );
  }
}
