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

    final textTheme = _textTheme(Brightness.light, scheme);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: DesignTokens.background,
      useMaterial3: true,
      textTheme: textTheme,
      navigationBarTheme: _navigationBarTheme(scheme, textTheme),
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
      seedColor: DesignTokens.primaryContainer,
      brightness: Brightness.dark,
    ).copyWith(
      primary: DesignTokens.darkPrimary,
      onPrimary: DesignTokens.darkOnPrimary,
      primaryContainer: DesignTokens.darkPrimaryContainer,
      onPrimaryContainer: DesignTokens.darkOnPrimaryContainer,
      secondary: DesignTokens.secondaryContainer,
      onSecondary: DesignTokens.onSecondaryContainer,
      secondaryContainer: DesignTokens.secondary,
      onSecondaryContainer: DesignTokens.onSecondary,
      tertiary: DesignTokens.onTertiaryContainer,
      onTertiary: DesignTokens.tertiary,
      tertiaryContainer: DesignTokens.tertiaryContainer,
      onTertiaryContainer: DesignTokens.onTertiaryContainer,
      error: DesignTokens.error,
      onError: DesignTokens.onError,
      errorContainer: DesignTokens.onErrorContainer,
      onErrorContainer: DesignTokens.errorContainer,
      surface: DesignTokens.darkSurface,
      onSurface: DesignTokens.darkOnSurface,
      onSurfaceVariant: DesignTokens.darkOnSurfaceVariant,
      outline: DesignTokens.darkOutline,
      outlineVariant: DesignTokens.darkOutlineVariant,
      surfaceContainerHighest: const Color(0xFF332839),
      surfaceContainerHigh: const Color(0xFF2E2433),
      surfaceContainer: DesignTokens.darkSurfaceContainer,
      surfaceContainerLow: DesignTokens.darkSurfaceContainerLow,
      surfaceContainerLowest: DesignTokens.darkSurfaceContainerLowest,
    );

    final textTheme = _textTheme(Brightness.dark, scheme);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: DesignTokens.darkBackground,
      useMaterial3: true,
      textTheme: textTheme,
      navigationBarTheme: _navigationBarTheme(scheme, textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: DesignTokens.darkBackground,
        foregroundColor: DesignTokens.darkOnSurface,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: DesignTokens.darkOnSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: DesignTokens.darkSurfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          side: const BorderSide(color: DesignTokens.darkOutlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DesignTokens.darkPrimaryContainer,
          foregroundColor: DesignTokens.darkOnPrimaryContainer,
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
          foregroundColor: DesignTokens.darkPrimary,
          minimumSize: const Size(DesignTokens.touchTargetMin, DesignTokens.touchTargetMin),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
          side: const BorderSide(color: DesignTokens.darkOutlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.darkSurfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLg,
          vertical: DesignTokens.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          borderSide: const BorderSide(color: DesignTokens.darkOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          borderSide: const BorderSide(color: DesignTokens.darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          borderSide: const BorderSide(
            color: DesignTokens.darkPrimary,
            width: 2,
          ),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: DesignTokens.darkOnSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.darkSurfaceContainerLow,
        selectedColor: DesignTokens.darkPrimaryContainer.withValues(alpha: 0.35),
        labelStyle: textTheme.labelLarge,
        side: const BorderSide(color: DesignTokens.darkOutlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DesignTokens.darkOutlineVariant,
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
        backgroundColor: DesignTokens.darkSurfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMd,
          side: const BorderSide(color: DesignTokens.darkOutlineVariant),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }

  static NavigationBarThemeData _navigationBarTheme(
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 80,
      indicatorColor: scheme.primaryContainer.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium?.copyWith(
          color: selected ? scheme.primaryContainer : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.primaryContainer : scheme.onSurfaceVariant,
        );
      }),
    );
  }

  static TextTheme _textTheme(Brightness brightness, ColorScheme scheme) {
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
        color: scheme.onSurface,
      ),
      headlineMedium: hanken.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: scheme.onSurface,
      ),
      titleLarge: hanken.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: scheme.onSurface,
      ),
      displaySmall: hanken.displaySmall?.copyWith(
        color: scheme.onSurface,
      ),
      bodyLarge: hanken.bodyLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 26 / 18,
        color: scheme.onSurface,
      ),
      bodyMedium: hanken.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: scheme.onSurface,
      ),
      labelLarge: hanken.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      labelMedium: hanken.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.5,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: hanken.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
