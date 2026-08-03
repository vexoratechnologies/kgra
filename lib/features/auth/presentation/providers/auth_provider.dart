import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// AuthProvider manages the state of login, OTP verification, and registration.
/// 
/// It exposes parameters for loading, errors, user approval status, and auth state.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // UI state variables
  bool _isLoading = false;
  String? _error;
  UserModel? _currentUser;
  
  // Verification states
  String? _verificationPhone;
  String? _tempName;
  String? _tempDesignation;
  String? _tempInstitution;
  String? _tempPhotoBase64;
  String? _tempZone;
  String? _tempDateOfBirth;
  String? _tempDateOfJoin;
  String? _tempMembershipId;
  String? _tempDateOfRetirement;
  bool _isVerificationCompleted = false;
  bool _isRegistered = false;
  bool _isPendingApproval = false;
  String? _currentUserPhotoBase64;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get currentUser => _currentUser;
  String? get currentUserPhotoBase64 => _currentUserPhotoBase64;
  String? get verificationPhone => _verificationPhone;
  bool get isVerificationCompleted => _isVerificationCompleted;
  bool get isRegistered => _isRegistered;
  bool get isPendingApproval => _isPendingApproval;
  bool get isAuthenticated => _currentUser != null && _currentUser!.isApproved;

  /// Sets loading state and notifies listeners
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Sets error state and notifies listeners
  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// Clear all local auth states (e.g. on starting over or errors)
  void clearStates() {
    _error = null;
    _verificationPhone = null;
    _tempName = null;
    _tempDesignation = null;
    _tempInstitution = null;
    _tempPhotoBase64 = null;
    _tempZone = null;
    _tempDateOfBirth = null;
    _tempDateOfJoin = null;
    _tempMembershipId = null;
    _tempDateOfRetirement = null;
    _isVerificationCompleted = false;
    _isRegistered = false;
    _isPendingApproval = false;
    _currentUserPhotoBase64 = null;
    notifyListeners();
  }

  /// Lazily fetches the current user's profile image base64.
  Future<void> _fetchCurrentUserImage() async {
    if (_currentUser == null || _currentUser!.profileImageId == null) {
      _currentUserPhotoBase64 = null;
      notifyListeners();
      return;
    }
    // If image resides in Firebase Storage, skip base64 load
    if (_currentUser!.profileImageId!.startsWith('http')) {
      _currentUserPhotoBase64 = null;
      notifyListeners();
      return;
    }
    try {
      final imgData = await _authRepository.getUserImage(_currentUser!.profileImageId!);
      if (imgData != null && imgData['imageBase64'] != null) {
        _currentUserPhotoBase64 = imgData['imageBase64'] as String;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load current user profile image: $e');
    }
  }

  /// Checks if an active session is running on app launch.
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    _setError(null);

    // 1. Try to restore instantly from local SharedPreferences cache
    try {
      final cachedUser = _authRepository.getCachedUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        _isRegistered = true;
        _isPendingApproval = !cachedUser.isApproved;
        _fetchCurrentUserImage();
        notifyListeners(); // Route immediately to prevent screen flickers
      }
    } catch (e) {
      debugPrint('Failed to load cached user session: $e');
    }

    // Wait for Firebase Auth to finish restoring its session asynchronously
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
      }
    } catch (e) {
      debugPrint('Firebase Auth initialization wait timed out or failed: $e');
    }

    // 2. Perform background fetch from remote database to check latest approval/details
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _isRegistered = true;
        _isPendingApproval = !user.isApproved;
        _fetchCurrentUserImage();
      } else {
        // Only clear cache and log out if there is actually NO active Firebase user session
        if (FirebaseAuth.instance.currentUser == null) {
          _currentUser = null;
          _isRegistered = false;
          _isPendingApproval = false;
          await _authRepository.clearUserCache();
        }
      }
      notifyListeners();
    } catch (e) {
      if (_currentUser == null) {
        _setError('Failed to restore login session: ${e.toString()}');
      } else {
        debugPrint('Failed to refresh session from server (working offline): $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Checks if a user is registered under the given mobile number.
  Future<bool> checkUserExists(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    try {
      // Ensure an anonymous session is running to satisfy Firestore security rules
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final exists = await _authRepository.checkUserExists(phoneNumber);
      return exists;
    } catch (e) {
      _setError('Failed to check user existence: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sets the active verification phone number state.
  void setVerificationPhone(String? phone) {
    _verificationPhone = phone;
    notifyListeners();
  }

  /// Triggers standard OTP generation/lookup logic.
  Future<bool> sendOtp(String phoneNumber, {
    String? tempName,
    String? tempDesignation,
    String? tempInstitution,
    String? tempPhotoBase64,
    String? tempZone,
    String? tempDateOfBirth,
    String? tempDateOfJoin,
    String? tempMembershipId,
    String? tempDateOfRetirement,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _verificationPhone = phoneNumber;
      _tempName = tempName;
      _tempDesignation = tempDesignation;
      _tempInstitution = tempInstitution;
      _tempPhotoBase64 = tempPhotoBase64;
      _tempZone = tempZone;
      _tempDateOfBirth = tempDateOfBirth;
      _tempDateOfJoin = tempDateOfJoin;
      _tempMembershipId = tempMembershipId;
      _tempDateOfRetirement = tempDateOfRetirement;
      await _authRepository.sendOtp(phoneNumber);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Verifies the OTP, signs in, and checks Firestore status.
  Future<bool> verifyOtp(String code) async {
    if (_verificationPhone == null) {
      _setError('Missing verification phone number.');
      return false;
    }
    
    _setLoading(true);
    _setError(null);
    try {
      final user = await _authRepository.verifyOtp(_verificationPhone!, code);
      
      _isVerificationCompleted = true;
      if (user == null) {
        // Verified but not registered in USERS DB
        _isRegistered = false;
        _isPendingApproval = false;
        
        // If they entered a registration name, register them immediately!
        if (_tempName != null && _tempName!.isNotEmpty) {
          final registered = await _registerWithUidAndName(
            _tempName!,
            designation: _tempDesignation,
            institution: _tempInstitution,
            photoBase64: _tempPhotoBase64,
            zone: _tempZone,
            dateOfBirth: _tempDateOfBirth,
            dateOfJoin: _tempDateOfJoin,
            membershipId: _tempMembershipId,
            dateOfRetirement: _tempDateOfRetirement,
          );
          if (!registered) {
            _setLoading(false);
            return false;
          }
        }
      } else {
        _isRegistered = true;
        if (user.isApproved && user.status == 'approved') {
          _currentUser = user;
          _isPendingApproval = false;
          _fetchCurrentUserImage();
        } else {
          _currentUser = null;
          _isPendingApproval = true;
        }
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Uploads a base64 profile image to Firebase Storage and returns the download URL.
  Future<String?> _uploadProfileImageToStorage(String uid, String photoBase64) async {
    try {
      final decodedBytes = base64Decode(photoBase64);
      final storageService = GetIt.instance<StorageService>();
      final downloadUrl = await storageService.uploadImage(
        folderName: 'profile_images',
        docId: uid,
        fileName: 'profile.jpg',
        fileBytes: decodedBytes,
      );
      return downloadUrl;
    } catch (e) {
      debugPrint('Failed to upload image to Firebase Storage: $e');
      return null;
    }
  }

  Future<bool> _registerWithUidAndName(
    String fullName, {
    String? designation,
    String? institution,
    String? photoBase64,
    String? zone,
    String? dateOfBirth,
    String? dateOfJoin,
    String? membershipId,
    String? dateOfRetirement,
  }) async {
    final uid = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      String? profileImageId;
      if (photoBase64 != null && photoBase64.isNotEmpty) {
        final downloadUrl = await _uploadProfileImageToStorage(uid, photoBase64);
        if (downloadUrl != null) {
          profileImageId = downloadUrl;
        } else {
          profileImageId = 'img_$uid';
          await _authRepository.saveUserImage(profileImageId, photoBase64);
        }
      }

      String? finalMembershipId = membershipId;
      if ((finalMembershipId == null || finalMembershipId.trim().isEmpty) && zone != null && zone.isNotEmpty) {
        finalMembershipId = await _authRepository.generateNextMembershipId(zone);
      }

      final newUser = UserModel(
        uid: uid,
        name: fullName,
        phoneNumber: _verificationPhone!,
        designation: designation,
        institution: institution,
        profileImageId: profileImageId,
        isApproved: false,
        status: 'pending',
        createdAt: DateTime.now(),
        zone: zone,
        dateOfBirth: dateOfBirth,
        dateOfJoin: dateOfJoin,
        membershipId: finalMembershipId,
        dateOfRetirement: dateOfRetirement,
      );
      await _authRepository.registerUser(newUser);
      _isRegistered = true;
      _isPendingApproval = true;
      return true;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> registerUser(
    String fullName, {
    String? designation,
    String? institution,
    String? photoBase64,
    String? zone,
    String? dateOfBirth,
    String? dateOfJoin,
    String? membershipId,
    String? dateOfRetirement,
  }) async {
    if (_verificationPhone == null) {
      _setError('No verified phone number found. Try verifying OTP first.');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      final uid = DateTime.now().millisecondsSinceEpoch.toString();
      String? profileImageId;
      if (photoBase64 != null && photoBase64.isNotEmpty) {
        final downloadUrl = await _uploadProfileImageToStorage(uid, photoBase64);
        if (downloadUrl != null) {
          profileImageId = downloadUrl;
        } else {
          profileImageId = 'img_$uid';
          await _authRepository.saveUserImage(profileImageId, photoBase64);
        }
      }

      String? finalMembershipId = membershipId;
      if ((finalMembershipId == null || finalMembershipId.trim().isEmpty) && zone != null && zone.isNotEmpty) {
        finalMembershipId = await _authRepository.generateNextMembershipId(zone);
      }

      final newUser = UserModel(
        uid: uid,
        name: fullName,
        phoneNumber: _verificationPhone!,
        designation: designation,
        institution: institution,
        profileImageId: profileImageId,
        isApproved: false,
        status: 'pending',
        createdAt: DateTime.now(),
        zone: zone,
        dateOfBirth: dateOfBirth,
        dateOfJoin: dateOfJoin,
        membershipId: finalMembershipId,
        dateOfRetirement: dateOfRetirement,
      );

      await _authRepository.registerUser(newUser);
      
      _isRegistered = true;
      _isPendingApproval = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Checks Firestore approval status if user is currently in pending state.
  Future<void> checkApprovalStatus() async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null && user.isApproved && user.status == 'approved') {
        _currentUser = user;
        _isPendingApproval = false;
        _fetchCurrentUserImage();
      }
    } catch (e) {
      _setError('Failed to check approval status: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Simulates admin approval locally when in mock mode.
  Future<void> simulateMockApproval() async {
    if (Firebase.apps.isNotEmpty) return;
    if (_verificationPhone == null) return;
    
    _setLoading(true);
    try {
      final user = await _authRepository.verifyOtp(_verificationPhone!, '123456');
      if (user != null) {
        final approvedUser = user.copyWith(isApproved: true, status: 'approved');
        await _authRepository.registerUser(approvedUser);
        _isPendingApproval = false;
        _currentUser = approvedUser;
        _fetchCurrentUserImage();
      }
    } catch (_) {}
    _setLoading(false);
  }

  /// Updates existing user profile details in Firestore and local state.
  Future<bool> updateUserProfile({
    required String name,
    String? phoneNumber,
    String? designation,
    String? institution,
    String? photoBase64,
    String? zone,
    String? dateOfBirth,
    String? dateOfJoin,
    String? membershipId,
    String? dateOfRetirement,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _setError(null);
    try {
      String? profileImageId = _currentUser!.profileImageId;
      if (photoBase64 != null && photoBase64.isNotEmpty) {
        final downloadUrl = await _uploadProfileImageToStorage(_currentUser!.uid, photoBase64);
        if (downloadUrl != null) {
          profileImageId = downloadUrl;
        } else {
          profileImageId = 'img_${_currentUser!.uid}';
          await _authRepository.saveUserImage(profileImageId, photoBase64);
          _currentUserPhotoBase64 = photoBase64;
        }
      }

      final updatedUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        designation: designation,
        institution: institution,
        profileImageId: profileImageId,
        zone: zone,
        dateOfBirth: dateOfBirth,
        dateOfJoin: dateOfJoin,
        membershipId: membershipId,
        dateOfRetirement: dateOfRetirement,
      );

      await _authRepository.updateUser(updatedUser);
      _currentUser = updatedUser;
      if (photoBase64 != null && photoBase64.isNotEmpty) {
        _currentUserPhotoBase64 = photoBase64;
      } else {
        await _fetchCurrentUserImage();
      }
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Logs the user out and clears states.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = null;
      _currentUserPhotoBase64 = null;
      clearStates();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Read-only preview of next membership ID for a zone.
  Future<String> peekNextMembershipId(String zone) async {
    return await _authRepository.peekNextMembershipId(zone);
  }

  /// Generates the next membership ID for a zone using atomic transaction.
  Future<String> generateNextMembershipId(String zone) async {
    return await _authRepository.generateNextMembershipId(zone);
  }
}
