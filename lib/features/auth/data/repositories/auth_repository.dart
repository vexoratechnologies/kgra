import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/authentication_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/user_model.dart';

/// AuthRepository implements the clean contract for all authentication services.
/// 
/// It acts as the coordinator between AuthenticationService and FirestoreService.
class AuthRepository {
  final AuthenticationService _authService;
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;

  AuthRepository({
    required AuthenticationService authService,
    required FirestoreService firestoreService,
    required SharedPreferences prefs,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        _prefs = prefs;

  static const String _cachedUserKey = 'cached_current_user';

  /// Retrieves the locally cached user profile.
  UserModel? getCachedUser() {
    final jsonStr = _prefs.getString(_cachedUserKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      return UserModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  /// Caches the given user profile.
  Future<void> cacheUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _prefs.setString(_cachedUserKey, jsonStr);
  }

  /// Clears the cached user profile.
  Future<void> clearUserCache() async {
    await _prefs.remove(_cachedUserKey);
  }

  /// Checks if a user is registered under the given mobile number.
  Future<bool> checkUserExists(String phoneNumber) async {
    return await _firestoreService.userExists(phoneNumber);
  }

  /// Initiates OTP request flow.
  Future<void> sendOtp(String phoneNumber) async {
    await _authService.sendOtp(phoneNumber);
  }

  /// Verifies OTP code, establishes Firebase session, and fetches matching database user.
  /// 
  /// Returns the [UserModel] if registered, or null if registration is needed.
  Future<UserModel?> verifyOtp(String phoneNumber, String code) async {
    await _authService.verifyOtp(phoneNumber, code);
    
    // Check if the user document exists in Firestore
    final userModel = await _firestoreService.getUserByPhoneNumber(phoneNumber);
    if (userModel == null) {
      return null; // Phone verified, but registration details are missing
    }

    await cacheUser(userModel);
    return userModel;
  }

  /// Registers a new user request in Firestore.
  /// 
  /// Creates the document with `isApproved = false` and status = `'pending'`.
  Future<void> registerUser(UserModel user) async {
    await _firestoreService.saveUser(user);
    await cacheUser(user);
  }

  /// Saves user image base64 into the database.
  Future<void> saveUserImage(String profileImageId, String imageBase64) async {
    await _firestoreService.saveUserImage(profileImageId, imageBase64);
  }

  /// Retrieves user image details by ID.
  Future<Map<String, dynamic>?> getUserImage(String profileImageId) async {
    return await _firestoreService.getUserImage(profileImageId);
  }

  /// Gets the currently authenticated user details.
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    
    UserModel? user;
    // Look up by verified phone number if available
    if (firebaseUser.phoneNumber != null && firebaseUser.phoneNumber!.isNotEmpty) {
      user = await _firestoreService.getUserByPhoneNumber(firebaseUser.phoneNumber!);
    }
    
    // Fallback to direct UID document lookup
    user ??= await _firestoreService.getUserByUid(firebaseUser.uid);

    if (user != null) {
      await cacheUser(user);
    }
    return user;
  }

  /// Gets current Firebase Auth User ID.
  String? getCurrentUid() {
    return _authService.currentUser?.uid;
  }

  /// Signs out the user session.
  Future<void> signOut() async {
    await clearUserCache();
    await _authService.signOut();
  }
}
