import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock user representing a session when Firebase is unconfigured.
class MockUser {
  final String uid;
  MockUser(this.uid);
}

/// AuthenticationService manages Firebase Auth sessions and custom OTP verifications.
/// 
/// If Firebase is not initialized, it automatically falls back to local SharedPreferences
/// session caching to allow layout previews and OTP login testing without crashing.
class AuthenticationService {
  
  bool get _useMock => Firebase.apps.isEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseDatabase get _rtdb => FirebaseDatabase.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ==========================================
  // Mock Session Keys
  // ==========================================
  static const String _mockCurrentUidKey = 'mock_auth_current_uid';
  
  // In-memory cache for fast access
  String? _inMemoryMockUid;

  final SharedPreferences _prefs;

  AuthenticationService({required SharedPreferences prefs}) : _prefs = prefs {
    _initMockSession();
  }

  void _initMockSession() {
    if (_useMock) {
      _inMemoryMockUid = _prefs.getString(_mockCurrentUidKey);
    }
  }

  /// Returns the currently logged-in user (real Firebase User or MockUser).
  dynamic get currentUser {
    if (_useMock) {
      return _inMemoryMockUid != null ? MockUser(_inMemoryMockUid!) : null;
    }
    return _auth.currentUser;
  }

  /// Streams the authentication state changes.
  Stream<dynamic> get authStateChanges {
    if (_useMock) {
      // Return a simple stream emitting current local auth state
      return Stream.value(currentUser);
    }
    return _auth.authStateChanges();
  }

  /// Fetches the fixed OTP for a phone number.
  Future<String> getFixedOtpForNumber(String phoneNumber) async {
    String? resolvedOtp;
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final shortPhone = cleanPhone.startsWith('91') && cleanPhone.length == 12
        ? cleanPhone.substring(2)
        : cleanPhone;

    if (_useMock) {
      // In mock mode, we fallback directly to 123456 or look inside mock SharedPreferences
      resolvedOtp = _prefs.getString('mock_otp_$cleanPhone');
      if (resolvedOtp == null || resolvedOtp.isEmpty) {
        resolvedOtp = _prefs.getString('mock_otp_$shortPhone');
      }
      if (resolvedOtp == null || resolvedOtp.isEmpty) {
        resolvedOtp = '123456';
      }
      return resolvedOtp;
    }

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
  Future<dynamic> verifyOtp(String phoneNumber, String typedOtp) async {
    final expectedOtp = await getFixedOtpForNumber(phoneNumber);

    if (typedOtp != expectedOtp) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'The OTP entered is incorrect. Please try again.',
      );
    }

    if (_useMock) {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      final mockUid = 'mock_user_uid_$cleanPhone';
      
      await _prefs.setString(_mockCurrentUidKey, mockUid);
      _inMemoryMockUid = mockUid;
      
      return MockUser(mockUid);
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
    if (_useMock) {
      await _prefs.remove(_mockCurrentUidKey);
      _inMemoryMockUid = null;
      return;
    }
    await _auth.signOut();
  }
}
