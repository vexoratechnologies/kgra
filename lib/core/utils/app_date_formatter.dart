import 'package:intl/intl.dart';

/// Helper utility for normalizing and formatting dates throughout the app.
class AppDateFormatter {
  /// Formats date strings to 'dd-MM-yyyy'.
  /// Gracefully converts 'yyyy-MM-dd' or ISO date strings to 'dd-MM-yyyy'.
  /// Returns [fallback] if [dateStr] is null or empty.
  static String formatToDateMonthYear(String? dateStr, {String fallback = ''}) {
    if (dateStr == null || dateStr.trim().isEmpty) return fallback;
    final trimmed = dateStr.trim();
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
        final dt = DateTime.parse(trimmed);
        return DateFormat('dd-MM-yyyy').format(dt);
      }
    } catch (_) {}
    return trimmed;
  }
}
