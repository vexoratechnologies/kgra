import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_style.dart';
import 'app_radius.dart';

/// AppTheme manages the global Material 3 ThemeData configuration.
/// 
/// It encapsulates button themes, input fields, card schemas, typography scales
/// and navigation elements to ensure uniformity.
class AppTheme {
  AppTheme._();

  /// Returns the default light theme for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: AppColors.colorScheme,
      textTheme: AppTextStyle.textTheme,
      scaffoldBackgroundColor: AppColors.brandBackground,
      
      // Card Theme Setup (representing level 1 glassmorphic containers in plain styling fallback)
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.80),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg, // 16px
          side: BorderSide(
            color: AppColors.brandSecondary.withValues(alpha: 0.10),
            width: 1.0,
          ),
        ),
      ),
      
      // Elevated Button Theme (Primary Buttons)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderLg, // 16px
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600, // Semi-bold
            height: 1.428,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined Button Theme (Secondary Buttons)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          side: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderLg, // 16px
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600, // Semi-bold
            height: 1.428,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Text Button Theme (Tertiary/Ghost Buttons)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderLg, // 16px
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600, // Semi-bold
            height: 1.428,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input Decoration Theme (Enclosed 16px Containers)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // MD3 Filled but with very light gray #F1F5F9
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderLg, // 16px
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderLg, // 16px
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderLg, // 16px
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderLg, // 16px
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderLg, // 16px
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.outline,
        ),
      ),

      // Navigation Bar (Glassmorphic look and feel with Material 3 pill indicators)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.95), // 95% opacity
        elevation: 0,
        indicatorColor: AppColors.brandPrimary.withValues(alpha: 0.12), // Subtle primary pill
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.brandPrimary : AppColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.brandPrimary : AppColors.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
    );
  }
}
