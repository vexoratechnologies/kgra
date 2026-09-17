/// AuthConfig holds authentication constants and phone formatting helpers.
class AuthConfig {
  AuthConfig._();

  /// Default country code prefix for phone numbers if missing
  static const String defaultCountryCode = '+91';

  /// Pre-defined static fixed OTP numbers for testing or bypass logic.
  /// Format: Phone number (cleaned or E.164) -> Fixed OTP code
  static const Map<String, String> staticFixedOtps = {
    '9999999999': '123456',
    '+919999999999': '123456',
    '1234567890': '123456',
  };

  /// Normalizes phone number into E.164 format (e.g., '+919876543210').
  static String formatE164(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (phoneNumber.trim().startsWith('+')) {
      return '+$cleanPhone';
    }
    if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
      return '+$cleanPhone';
    }
    if (cleanPhone.length == 10) {
      return '$defaultCountryCode$cleanPhone';
    }
    return '+$cleanPhone';
  }

  /// Extracts standard 10-digit number or short number without country code
  static String formatShortNumber(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
      return cleanPhone.substring(2);
    }
    return cleanPhone;
  }
}
