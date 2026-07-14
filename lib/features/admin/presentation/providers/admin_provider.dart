import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/admin_model.dart';
import '../../data/repositories/admin_repository.dart';

/// AdminProvider manages state and user approval processes for the admin dashboard.
class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository;

  AdminProvider({required AdminRepository adminRepository})
      : _adminRepository = adminRepository;

  AdminModel? _currentAdmin;
  List<AdminModel> _admins = [];
  List<String> _zones = [];
  List<String> _designations = [];

  List<UserModel> _pendingUsers = [];
  List<UserModel> _approvedUsers = [];
  List<UserModel> _rejectedUsers = [];
  bool _isLoading = false;
  String? _error;

  // Cache base64 profile images by User UID to avoid redundant Firestore reads
  final Map<String, String> _userImages = {};
  final Set<String> _loadingImageUids = {};

  AdminModel? get currentAdmin => _currentAdmin;
  List<AdminModel> get admins => _admins;
  List<String> get zones => _zones;
  List<String> get designations => _designations;

  List<UserModel> get pendingUsers => _pendingUsers;
  List<UserModel> get approvedUsers => _approvedUsers;
  List<UserModel> get rejectedUsers => _rejectedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String> get userImages => _userImages;

  bool isImageLoading(String uid) => _loadingImageUids.contains(uid);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> _ensureAuthSession() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  /// Logs in administrative credentials.
  Future<bool> loginAdmin(String username, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final admin = await _adminRepository.getAdminByUsername(username);
      if (admin != null && admin.password == password) {
        _currentAdmin = admin;
        notifyListeners();
        return true;
      }
      _setError('Invalid username or password.');
      return false;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clears active admin session.
  void logoutAdmin() {
    _currentAdmin = null;
    notifyListeners();
  }

  /// Fetches pending registrations from database.
  Future<void> fetchPendingUsers() async {
    _setLoading(true);
    _setError(null);
    try {
      await _ensureAuthSession();
      _pendingUsers = await _adminRepository.getPendingUsers();
    } catch (e) {
      _setError('Failed to fetch pending users: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Approves a registration request.
  Future<bool> approveUser(String uid) async {
    _setError(null);
    try {
      await _adminRepository.updateUserStatus(uid, 'approved', true);
      final userIndex = _pendingUsers.indexWhere((u) => u.uid == uid);
      if (userIndex != -1) {
        final user = _pendingUsers[userIndex].copyWith(status: 'approved', isApproved: true);
        _pendingUsers.removeAt(userIndex);
        _approvedUsers.removeWhere((u) => u.uid == uid);
        _approvedUsers.add(user);
      }
      _userImages.remove(uid);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Approval failed: ${e.toString()}');
      return false;
    }
  }

  /// Rejects a registration request.
  Future<bool> rejectUser(String uid) async {
    _setError(null);
    try {
      await _adminRepository.updateUserStatus(uid, 'rejected', false);
      final userIndex = _pendingUsers.indexWhere((u) => u.uid == uid);
      if (userIndex != -1) {
        final user = _pendingUsers[userIndex].copyWith(status: 'rejected', isApproved: false);
        _pendingUsers.removeAt(userIndex);
        _rejectedUsers.removeWhere((u) => u.uid == uid);
        _rejectedUsers.add(user);
      }
      _userImages.remove(uid);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Rejection failed: ${e.toString()}');
      return false;
    }
  }

  /// Lazy-loads user profile image base64 on-demand.
  Future<void> fetchUserImage(String profileImageId, String userUid) async {
    if (_userImages.containsKey(userUid) || _loadingImageUids.contains(userUid)) {
      return;
    }

    _loadingImageUids.add(userUid);
    notifyListeners();

    try {
      final imgData = await _adminRepository.getUserImage(profileImageId);
      if (imgData != null && imgData['imageBase64'] != null) {
        _userImages[userUid] = imgData['imageBase64'] as String;
      }
    } catch (e) {
      debugPrint('Failed to load image for $userUid: $e');
    } finally {
      _loadingImageUids.remove(userUid);
      notifyListeners();
    }
  }

  /// Fetches approved registrations from database.
  Future<void> fetchApprovedUsers() async {
    _setLoading(true);
    _setError(null);
    try {
      await _ensureAuthSession();
      _approvedUsers = await _adminRepository.getUsersByStatus('approved');
    } catch (e) {
      _setError('Failed to fetch approved users: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches rejected registrations from database.
  Future<void> fetchRejectedUsers() async {
    _setLoading(true);
    _setError(null);
    try {
      await _ensureAuthSession();
      _rejectedUsers = await _adminRepository.getUsersByStatus('rejected');
    } catch (e) {
      _setError('Failed to fetch rejected users: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================
  // Admin & Zones Operations
  // ==========================================

  Future<void> fetchAdmins() async {
    _setLoading(true);
    try {
      _admins = await _adminRepository.getAdmins();
    } catch (e) {
      _setError('Failed to fetch admins: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchZones() async {
    _setLoading(true);
    try {
      _zones = await _adminRepository.getZones();
    } catch (e) {
      _setError('Failed to fetch zones: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addAdmin(AdminModel admin) async {
    _setError(null);
    try {
      await _adminRepository.saveAdmin(admin);
      await fetchAdmins();
      return true;
    } catch (e) {
      _setError('Failed to add admin: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteAdmin(String username) async {
    _setError(null);
    try {
      await _adminRepository.deleteAdmin(username);
      await fetchAdmins();
      return true;
    } catch (e) {
      _setError('Failed to delete admin: ${e.toString()}');
      return false;
    }
  }

  Future<bool> addZone(String name) async {
    _setError(null);
    try {
      await _adminRepository.saveZone(name);
      await fetchZones();
      return true;
    } catch (e) {
      _setError('Failed to add zone: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteZone(String name) async {
    _setError(null);
    try {
      await _adminRepository.deleteZone(name);
      await fetchZones();
      return true;
    } catch (e) {
      _setError('Failed to delete zone: ${e.toString()}');
      return false;
    }
  }

  Future<void> fetchDesignations() async {
    _setLoading(true);
    try {
      _designations = await _adminRepository.getDesignations();
    } catch (e) {
      _setError('Failed to fetch designations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addDesignation(String name) async {
    _setError(null);
    try {
      await _adminRepository.saveDesignation(name);
      await fetchDesignations();
      return true;
    } catch (e) {
      _setError('Failed to add designation: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteDesignation(String name) async {
    _setError(null);
    try {
      await _adminRepository.deleteDesignation(name);
      await fetchDesignations();
      return true;
    } catch (e) {
      _setError('Failed to delete designation: ${e.toString()}');
      return false;
    }
  }
}
