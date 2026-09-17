import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/auth_config.dart';

/// AuthenticationService manages Firebase Phone Authentication, sessions,
/// and fixed/test OTP verifications.
class AuthenticationService {
  AuthenticationService();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseDatabase get _rtdb => FirebaseDatabase.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? _verificationId;
  int? _resendToken;
  String? _lastSentPhone;

  /// Returns the currently logged-in real Firebase User.
  User? get currentUser {
    return _auth.currentUser;
  }

  /// Streams the authentication state changes.
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  /// Checks and returns the fixed OTP for a phone number if present in:
  /// 1. Static config map ([AuthConfig.staticFixedOtps])
  /// 2. Firebase Realtime Database (`fixed_otp` node)
  /// 3. Cloud Firestore (`fixed_otp` collection)
  /// 
  /// Returns `null` if the phone number is NOT in the fixed OTP list.
  Future<String?> getFixedOtpForNumber(String phoneNumber) async {
    String? resolvedOtp;
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final shortPhone = AuthConfig.formatShortNumber(phoneNumber);
    final formattedE164 = AuthConfig.formatE164(phoneNumber);

    // 1. Check static fixed OTP map in AuthConfig
    if (AuthConfig.staticFixedOtps.containsKey(cleanPhone)) {
      resolvedOtp = AuthConfig.staticFixedOtps[cleanPhone];
    } else if (AuthConfig.staticFixedOtps.containsKey(shortPhone)) {
      resolvedOtp = AuthConfig.staticFixedOtps[shortPhone];
    } else if (AuthConfig.staticFixedOtps.containsKey(formattedE164)) {
      resolvedOtp = AuthConfig.staticFixedOtps[formattedE164];
    }

    if (resolvedOtp != null && resolvedOtp.isNotEmpty) {
      debugPrint('Found fixed OTP in static config: $resolvedOtp for $phoneNumber');
      return resolvedOtp;
    }

    // 2. Query Firebase Realtime Database "fixed_otp" node
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
        if (resolvedOtp != null && resolvedOtp.isNotEmpty) {
          debugPrint('Fetched fixed OTP from RTDB: $resolvedOtp for $cleanPhone / $shortPhone');
          return resolvedOtp;
        }
      }
    } catch (e) {
      debugPrint('Realtime Database OTP query failed (normal if not configured): $e');
    }

    // 3. Query Cloud Firestore "fixed_otp" collection
    try {
      var doc = await _firestore.collection('fixed_otp').doc(cleanPhone).get();
      if (!doc.exists && cleanPhone != shortPhone) {
        doc = await _firestore.collection('fixed_otp').doc(shortPhone).get();
      }
      if (doc.exists && doc.data() != null) {
        resolvedOtp = doc.data()!['otp']?.toString();
        if (resolvedOtp != null && resolvedOtp.isNotEmpty) {
          debugPrint('Fetched fixed OTP from Firestore: $resolvedOtp for $cleanPhone / $shortPhone');
          return resolvedOtp;
        }
      }
    } catch (e) {
      debugPrint('Firestore OTP query failed (normal if not configured): $e');
    }

    // Number is NOT in fixed OTP list
    return null;
  }

  /// Initiates SMS OTP sending flow via Firebase Phone Authentication.
  /// 
  /// - If the phone number is in the fixed OTP list: Skips SMS sending.
  /// - If the phone number is NOT in the fixed OTP list: Sends SMS OTP via Firebase Auth.
  Future<void> sendOtp(String phoneNumber) async {
    final fixedOtp = await getFixedOtpForNumber(phoneNumber);

    if (fixedOtp != null) {
      debugPrint('Number $phoneNumber is in fixed OTP list. Skipping Firebase SMS send.');
      return;
    }

    final formattedPhone = AuthConfig.formatE164(phoneNumber);
    debugPrint('Sending Firebase Phone Auth SMS OTP to $formattedPhone...');

    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: (formattedPhone == _lastSentPhone) ? _resendToken : null,
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('Firebase Phone Auth: Automatic instant verification completed.');
        try {
          await _auth.signInWithCredential(credential);
        } catch (e) {
          debugPrint('Auto sign-in with credential failed: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('Firebase Phone Auth verification failed: [${e.code}] ${e.message}');
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('Firebase SMS OTP code sent successfully. VerificationId: $verificationId');
        _verificationId = verificationId;
        _resendToken = resendToken;
        _lastSentPhone = formattedPhone;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('Firebase Phone Auth auto retrieval timeout. VerificationId: $verificationId');
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  /// Verifies OTP and signs the user in.
  /// 
  /// - If the phone number is in the fixed OTP list: Verifies against the fixed OTP.
  /// - If the phone number is NOT in the fixed OTP list: Verifies code via Firebase Phone Auth credential.
  Future<User> verifyOtp(String phoneNumber, String typedOtp) async {
    final fixedOtp = await getFixedOtpForNumber(phoneNumber);

    if (fixedOtp != null) {
      // Check against fixed OTP list
      if (typedOtp != fixedOtp) {
        throw FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'The OTP entered is incorrect. Please try again.',
        );
      }
      debugPrint('Fixed OTP successfully verified for $phoneNumber');

      // Establish a session if no user is signed in
      if (_auth.currentUser == null) {
        final authResult = await _auth.signInAnonymously();
        if (authResult.user == null) {
          throw FirebaseAuthException(
            code: 'sign-in-failed',
            message: 'Unable to establish secure session.',
          );
        }
        return authResult.user!;
      }
      return _auth.currentUser!;
    }

    // Check if user was already auto-verified by Android SMS retriever
    final formattedPhone = AuthConfig.formatE164(phoneNumber);
    if (_auth.currentUser != null &&
        _auth.currentUser!.phoneNumber != null &&
        AuthConfig.formatE164(_auth.currentUser!.phoneNumber!) == formattedPhone) {
      debugPrint('User already auto-verified with Firebase Phone Auth for $formattedPhone');
      return _auth.currentUser!;
    }

    if (_verificationId == null) {
      throw FirebaseAuthException(
        code: 'session-expired',
        message: 'Verification session expired or invalid. Please request a new OTP.',
      );
    }

    // Verify against Firebase Phone Auth
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: typedOtp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'sign-in-failed',
          message: 'Unable to establish secure session.',
        );
      }

      debugPrint('Firebase SMS OTP successfully verified for $formattedPhone (UID: ${userCredential.user!.uid})');
      return userCredential.user!;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'The OTP entered is incorrect or expired. Please try again.',
      );
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    _verificationId = null;
    _resendToken = null;
    _lastSentPhone = null;
    await _auth.signOut();
  }
}
