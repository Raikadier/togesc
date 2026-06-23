import 'package:flutter/material.dart';

/// Tokens del design system Harmonic Precision (Stitch / Material 3).
abstract final class DesignTokens {
  // --- Marca y superficies ---
  static const Color background = Color(0xFFFFF7FC);
  static const Color onBackground = Color(0xFF1E1B1E);
  static const Color surface = Color(0xFFFFF7FC);
  static const Color onSurface = Color(0xFF1E1B1E);
  static const Color onSurfaceVariant = Color(0xFF4D4351);
  static const Color surfaceContainerLow = Color(0xFFF9F1F6);
  static const Color surfaceContainer = Color(0xFFF3ECF1);
  static const Color surfaceContainerHigh = Color(0xFFEEE6EB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF7F7383);
  static const Color outlineVariant = Color(0xFFD0C2D3);

  // --- Primarios ---
  static const Color primary = Color(0xFF4E0078);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF6A1B9A);
  static const Color onPrimaryContainer = Color(0xFFDA9CFF);

  // --- Secundarios ---
  static const Color secondary = Color(0xFF9A25AE);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFED76FD);
  static const Color onSecondaryContainer = Color(0xFF69007A);

  // --- Terciarios ---
  static const Color tertiary = Color(0xFF402747);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF573D5F);
  static const Color onTertiaryContainer = Color(0xFFCBAAD2);

  // --- Error ---
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // --- Feedback musical (semánticos Stitch) ---
  static const Color correct = Color(0xFF2E7D32);
  static const Color incorrect = Color(0xFFC62828);
  static const Color selection = Color(0xFFFFB300);

  // --- Piano ---
  static const Color pianoWhite = Color(0xFFFFFFFF);
  static const Color pianoBlack = Color(0xFF212121);

  // --- Tema oscuro Harmonic Precision ---
  static const Color darkBackground = Color(0xFF141018);
  static const Color darkOnBackground = Color(0xFFECE0E8);
  static const Color darkSurface = Color(0xFF141018);
  static const Color darkOnSurface = Color(0xFFECE0E8);
  static const Color darkOnSurfaceVariant = Color(0xFFCFC3CD);
  static const Color darkSurfaceContainerLow = Color(0xFF1E1622);
  static const Color darkSurfaceContainer = Color(0xFF281F2C);
  static const Color darkSurfaceContainerLowest = Color(0xFF1A121E);
  static const Color darkOutline = Color(0xFF988E98);
  static const Color darkOutlineVariant = Color(0xFF4D4351);
  static const Color darkPrimary = Color(0xFFDA9CFF);
  static const Color darkOnPrimary = Color(0xFF4E0078);
  static const Color darkPrimaryContainer = Color(0xFF6A1B9A);
  static const Color darkOnPrimaryContainer = Color(0xFFF3D4FF);

  // --- Forma y espaciado ---
  static const double radiusMd = 12;
  static const double radiusXl = 16;
  static const double shellBreakpoint = 600;
  static const double touchTargetMin = 48;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double marginMobile = 16;

  static BorderRadius get borderRadiusMd =>
      BorderRadius.circular(radiusMd);

  static BorderRadius get borderRadiusXl =>
      BorderRadius.circular(radiusXl);

  // --- Modo velocidad (Stitch speed-gradient) ---
  static const Color speedAccent = Color(0xFFE64A19);
  static const Color speedContainer = Color(0xFFFFEBE6);

  static const LinearGradient speedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5722), Color(0xFFB71C1C)],
  );

  /// Gradiente Pro (Stitch pro-gradient).
  static const LinearGradient proGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryContainer, secondary],
  );

  /// Sombra suave para cards hover (web/desktop).
  static List<BoxShadow> get cardHoverShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
