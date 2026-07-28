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

  /// Format raw Firebase/Firestore exception messages into polished human-readable warnings
  static String _formatFirebaseError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('permission-denied') || lower.contains('permission')) {
      return 'Access Denied: You do not have permission to execute this operation.';
    } else if (lower.contains('network-request-failed') || lower.contains('network')) {
      return 'Network Error: Please check your internet connection and try again.';
    } else if (lower.contains('user-not-found') || lower.contains('no-user')) {
      return 'Account not found. Please register first.';
    } else if (lower.contains('wrong-password') || lower.contains('invalid-credential')) {
      return 'Incorrect credentials. Please try again.';
    } else if (lower.contains('invalid-phone-number')) {
      return 'The phone number entered is invalid.';
    } else if (lower.contains('too-many-requests')) {
      return 'Too many requests. Please try again later.';
    } else if (lower.contains('session-expired')) {
      return 'Your session has expired. Please log in again.';
    } else if (lower.contains('unavailable')) {
      return 'Service is temporarily unavailable. Please try again later.';
    }
    
    // Strip technical tag like "[cloud_firestore/permission-denied]" if present
    if (error.contains(']')) {
      return error.split(']').last.trim();
    }
    return error;
  }

  static void _show(BuildContext context, String rawMessage, {required bool isError}) {
    final message = isError ? _formatFirebaseError(rawMessage) : rawMessage;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
