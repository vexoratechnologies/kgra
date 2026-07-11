import 'package:flutter/material.dart';

/// AppRadius defines the corner radii used across the app to deliver the
/// soft, approachable yet clean rounded aesthetic of Clinical Integrity.
class AppRadius {
  AppRadius._();

  /// Small corner radius (4.0 px)
  static const double sm = 4.0;

  /// Default corner radius (8.0 px) - e.g., chips, tags, small icons
  static const double defaultRadius = 8.0;

  /// Medium corner radius (12.0 px)
  static const double md = 12.0;

  /// Large corner radius (16.0 px) - e.g., standard containers, cards, buttons, input fields
  static const double lg = 16.0;

  /// Extra large corner radius (24.0 px)
  static const double xl = 24.0;

  /// Fully rounded corner radius (9999.0 px) - e.g., badges, pill tabs
  static const double full = 9999.0;

  // ==========================================
  // BorderRadius Helper Objects
  // ==========================================

  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderDefault => BorderRadius.circular(defaultRadius);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderFull => BorderRadius.circular(full);
}
