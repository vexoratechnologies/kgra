import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// AppSnackBar provides beautiful, premium, custom styled floating SnackBars
/// and automatically formats raw Firebase/Firestore technical errors into user-friendly messages.
class AppSnackBar {
  AppSnackBar._();

  /// Displays a customized Error SnackBar, automatically cleaning any Firebase technical terms
  static void showError(BuildContext context, String message) {
    _show(context, message, isError: true);
  }

  /// Displays a customized Success SnackBar
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, isError: false);
  }



  static void _show(BuildContext context, String rawMessage, {required bool isError}) {
    final message = rawMessage.trim().isNotEmpty ? rawMessage.trim() : 'An unexpected error occurred.';
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.brandAccent : const Color(0xFF1B4D3E), // Deep elegant crimson or hunter green
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        duration: const Duration(seconds: 8),
      ),
    );
  }
}
