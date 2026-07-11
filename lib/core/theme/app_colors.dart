import 'package:flutter/material.dart';

/// AppColors defines the complete color system for the Clinical Integrity theme.
/// 
/// It provides access to the brand colors (Deep Red, Sophisticated Gray, Background)
/// as well as the standard Material 3 color mapping from the specification.
class AppColors {
  AppColors._();

  // ==========================================
  // Brand specific colors from description
  // ==========================================
  
  /// Primary Deep Red associated with Kerala Government Radiographers' Association.
  static const Color brandPrimary = Color(0xFF7F0010);
  
  /// Sophisticated dark gray used for headers and structural elements.
  static const Color brandSecondary = Color(0xFF5F5E5E);
  
  /// Accent Red/Tint reserved for highlights, progress indicators, and "New" badges.
  static const Color brandAccent = Color(0xFFB02C2D);
  
  /// Sterile light white/gray background to reduce eye strain.
  static const Color brandBackground = Color(0xFFF8F9FA);

  /// Linear gradient from brandPrimary to brandAccent (135 degrees)
  static const Gradient brandGradient = LinearGradient(
    colors: [brandPrimary, brandAccent],
    begin: Alignment(-0.7, -0.7), // roughly 135 degrees
    end: Alignment(0.7, 0.7),
  );

  // ==========================================
  // Material 3 Color Palette from YAML
  // ==========================================
  static const Color primary = Color(0xFF7F0010);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFA12024);
  static const Color onPrimaryContainer = Color(0xFFFFB5B0);
  static const Color inversePrimary = Color(0xFFFFB3AE);
  
  static const Color secondary = Color(0xFF5F5E5E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE2DFDE);
  static const Color onSecondaryContainer = Color(0xFF636262);
  
  static const Color tertiary = Color(0xFF383D42);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF4F5459);
  static const Color onTertiaryContainer = Color(0xFFC4C8CE);

  static const Color background = Color(0xFFF8F9FA);
  static const Color onBackground = Color(0xFF191C1D);

  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceDim = Color(0xFFD9DADB);
  static const Color surfaceBright = Color(0xFFF8F9FA);
  static const Color surfaceVariant = Color(0xFFE1E3E4);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF59413F);
  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F2);
  static const Color surfaceTint = Color(0xFFB02C2D);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);

  static const Color outline = Color(0xFF8D706E);
  static const Color outlineVariant = Color(0xFFE1BFBC);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color primaryFixed = Color(0xFFFFDAD7);
  static const Color primaryFixedDim = Color(0xFFFFB3AE);
  static const Color onPrimaryFixed = Color(0xFF410004);
  static const Color onPrimaryFixedVariant = Color(0xFF8E1019);

  static const Color secondaryFixed = Color(0xFFE5E2E1);
  static const Color secondaryFixedDim = Color(0xFFC8C6C5);
  static const Color onSecondaryFixed = Color(0xFF1B1C1C);
  static const Color onSecondaryFixedVariant = Color(0xFF474746);

  static const Color tertiaryFixed = Color(0xFFDFE3E9);
  static const Color tertiaryFixedDim = Color(0xFFC3C7CD);
  static const Color onTertiaryFixed = Color(0xFF171C20);
  static const Color onTertiaryFixedVariant = Color(0xFF43474C);

  // ==========================================
  // Helper methods to generate light/dark ColorScheme
  // ==========================================
  
  /// Generates the standard ColorScheme based on the Clinical Integrity colors
  static ColorScheme get colorScheme {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      background: background,
      onBackground: onBackground,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF000000),
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
      surfaceTint: surfaceTint,
    );
  }
}
