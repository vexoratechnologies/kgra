import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// AuthenticationService manages Firebase Auth sessions and custom OTP verifications.
class AuthenticationService {
  AuthenticationService();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseDatabase get _rtdb => FirebaseDatabase.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Returns the currently logged-in real Firebase User.
  User? get currentUser {
    return _auth.currentUser;
  }

  /// Streams the authentication state changes.
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  /// Fetches the fixed OTP for a phone number.
  Future<String> getFixedOtpForNumber(String phoneNumber) async {
    String? resolvedOtp;
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final shortPhone = cleanPhone.startsWith('91') && cleanPhone.length == 12
        ? cleanPhone.substring(2)
        : cleanPhone;

    // 1. Try querying Firebase Realtime Database
    try {
      var ref = _rtdb.ref('fixed_otp').child(cleanPhone);
      var snapshot = await ref.get();
      if (!snapshot.exists && cleanPhone != shortPhone) {
        ref = _rtdb.ref('fixed_otp').child(shortPhone);
        snapshot = await ref.get();
      }
      if (snapshot.exists) {
        if (snapshot.value is Map) {
          resolvedOtp = (snapshot.value as Map)['otp']?.toString();
        } else {
          resolvedOtp = snapshot.value?.toString();
        }
        debugPrint('Fetched OTP from RTDB: $resolvedOtp for $cleanPhone / $shortPhone');
      }
    } catch (e) {
      debugPrint('Realtime Database OTP query failed (normal if not configured): $e');
    }

    // 2. Try querying Firestore "fixed_otp" collection
    if (resolvedOtp == null) {
      try {
        var doc = await _firestore.collection('fixed_otp').doc(cleanPhone).get();
        if (!doc.exists && cleanPhone != shortPhone) {
          doc = await _firestore.collection('fixed_otp').doc(shortPhone).get();
        }
        if (doc.exists && doc.data() != null) {
          resolvedOtp = doc.data()!['otp']?.toString();
          debugPrint('Fetched OTP from Firestore: $resolvedOtp for $cleanPhone / $shortPhone');
        }
      } catch (e) {
        debugPrint('Firestore OTP query failed (normal if not configured): $e');
      }
    }

    // 3. Fallback: return default OTP for testing (e.g. '123456')
    if (resolvedOtp == null || resolvedOtp.isEmpty) {
      resolvedOtp = '123456';
      debugPrint('No database OTP found. Falling back to default: 123456');
    }

    return resolvedOtp;
  }

  /// Initiates OTP sending flow.
  Future<void> sendOtp(String phoneNumber) async {
    await getFixedOtpForNumber(phoneNumber);
  }

  /// Verifies OTP and signs the user in.
  Future<User> verifyOtp(String phoneNumber, String typedOtp) async {
    final expectedOtp = await getFixedOtpForNumber(phoneNumber);

    if (typedOtp != expectedOtp) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'The OTP entered is incorrect. Please try again.',
      );
    }

    // Sign in anonymously to instantiate a Firebase session
    final authResult = await _auth.signInAnonymously();
    if (authResult.user == null) {
      throw FirebaseAuthException(
        code: 'sign-in-failed',
        message: 'Unable to establish secure session.',
      );
    }

    return authResult.user!;
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
