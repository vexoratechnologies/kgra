import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTextStyle defines the typography scale for the Clinical Integrity design system.
/// 
/// It utilizes Plus Jakarta Sans exclusively for all styles to ensure optimal legibility
/// and modern corporate presentation.
class AppTextStyle {
  AppTextStyle._();

  /// Plus Jakarta Sans base text style generator
  static TextStyle _plusJakartaSans({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // ==========================================
  // Typography Definitions
  // ==========================================

  /// Large display style for splash screens, dashboard key highlights, etc.
  /// Plus Jakarta Sans, 48px, bold (700), height 60px, spacing -0.02em.
  static TextStyle displayLg({Color? color}) => _plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 60.0 / 48.0, // 1.25
        letterSpacing: -0.02 * 48.0, // -0.96
        color: color,
      );

  /// Large headline style for desktop views or main headers.
  /// Plus Jakarta Sans, 32px, bold (700), height 40px.
  static TextStyle headlineLg({Color? color}) => _plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40.0 / 32.0, // 1.25
        color: color,
      );

  /// Medium headline style.
  /// Plus Jakarta Sans, 24px, semi-bold (600), height 32px.
  static TextStyle headlineMd({Color? color}) => _plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32.0 / 24.0, // ~1.333
        color: color,
      );

  /// Small headline style.
  /// Plus Jakarta Sans, 20px, semi-bold (600), height 28px.
  static TextStyle headlineSm({Color? color}) => _plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28.0 / 20.0, // 1.4
        color: color,
      );

  /// Large body text style for main reading contents.
  /// Plus Jakarta Sans, 18px, regular (400), height 28px.
  static TextStyle bodyLg({Color? color}) => _plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28.0 / 18.0, // ~1.556
        color: color,
      );

  /// Medium body text style for standard body/description.
  /// Plus Jakarta Sans, 16px, regular (400), height 24px.
  static TextStyle bodyMd({Color? color}) => _plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24.0 / 16.0, // 1.5
        color: color,
      );

  /// Small body text style.
  /// Plus Jakarta Sans, 14px, regular (400), height 20px.
  static TextStyle bodySm({Color? color}) => _plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20.0 / 14.0, // ~1.429
        color: color,
      );

  /// Label text style.
  /// Plus Jakarta Sans, 12px, semi-bold (600), height 16px, letterSpacing 0.05em.
  static TextStyle labelMd({Color? color}) => _plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16.0 / 12.0, // ~1.333
        letterSpacing: 0.05 * 12.0, // 0.6
        color: color,
      );

  /// Large headline style optimized for mobile views.
  /// Plus Jakarta Sans, 28px, bold (700), height 36px.
  static TextStyle headlineLgMobile({Color? color}) => _plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36.0 / 28.0, // ~1.286
        color: color,
      );

  // Keep compatibility mappings for prior calls
  static TextStyle titleLg({Color? color}) => headlineSm(color: color);
  static TextStyle labelSm({Color? color}) => labelMd(color: color);

  /// Combines styles into a standard Material TextTheme
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: displayLg(),
      headlineLarge: headlineLg(),
      headlineMedium: headlineMd(),
      headlineSmall: headlineSm(),
      titleLarge: titleLg(),
      bodyLarge: bodyLg(),
      bodyMedium: bodyMd(),
      bodySmall: bodySm(),
      labelLarge: labelMd(),
      labelMedium: labelSm(),
    );
  }
}
