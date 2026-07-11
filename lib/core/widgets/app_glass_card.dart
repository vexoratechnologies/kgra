import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// AppGlassCard provides a premium Glassmorphic card design according to the
/// Clinical Integrity guidelines:
/// - White container with 80% opacity
/// - 1px inner white border (light refractive edge)
/// - Backdrop filter blur (12px to 20px)
/// - 1px outer stroke of secondary navy at 10% opacity
/// - Ambient Navy tint shadow (offset Y-axis, 5% opacity)
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.width,
    this.height,
    this.borderRadius = AppRadius.lg, // 16px default
    this.blur = 16.0, // 16px blur (midpoint of 12-20px)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // Ambient Shadow: Soft, diffused Navy tint at 5% opacity, offset Y-axis
        boxShadow: [
          BoxShadow(
            color: AppColors.brandSecondary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(borderRadius),
              // Dual-stroke border: outer secondary tint at 10% opacity and inner white highlight
              border: Border.all(
                color: AppColors.brandSecondary.withValues(alpha: 0.10),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
