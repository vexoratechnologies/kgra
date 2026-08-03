import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/admin_model.dart';
import '../../data/repositories/admin_repository.dart';

/// AdminProvider manages state and user approval processes for the admin dashboard.
class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository;
  final SharedPreferences _prefs;

  static const String _cachedAdminKey = 'cached_current_admin';

  AdminProvider({
    required AdminRepository adminRepository,
    required SharedPreferences prefs,
  })  : _adminRepository = adminRepository,
        _prefs = prefs;

  AdminModel? _currentAdmin;
  List<AdminModel> _admins = [];
  List<String> _zones = ['Executive Committee'];
  List<String> _designations = [];

  List<UserModel> _pendingUsers = [];
  List<UserModel> _approvedUsers = [];
  List<UserModel> _rejectedUsers = [];
  String _selectedZoneFilter = 'All Zones';
  bool _isLoading = false;
  String? _error;

  // Cache base64 profile images by User UID to avoid redundant Firestore reads
  final Map<String, String> _userImages = {};
  final Set<String> _loadingImageUids = {};

  AdminModel? get currentAdmin => _currentAdmin;
  List<AdminModel> get admins => _admins;
  List<String> get zones => _zones;
  List<String> get designations => _designations;
  String get selectedZoneFilter => _selectedZoneFilter;

  void setSelectedZoneFilter(String zone) {
    _selectedZoneFilter = zone;
    notifyListeners();
  }

  List<UserModel> get pendingUsers {
    debugPrint('pendingUsers called. Total raw users: ${_pendingUsers.length}');
    if (_selectedZoneFilter == 'All Zones' || _selectedZoneFilter.isEmpty) {
      return _pendingUsers;
    }
    final targetZone = _selectedZoneFilter.trim().toLowerCase();
    debugPrint('Filtering pending users for selected zone filter: "$targetZone"');
    final filtered = _pendingUsers.where((u) {
      final userZone = u.zone?.trim().toLowerCase();
      if (userZone == null || userZone.isEmpty || userZone == 'null') {
        return true; // Show users with unassigned zone
      }
      final matches = (userZone == targetZone) ||
          userZone.contains(targetZone) ||
          targetZone.contains(userZone);
      debugPrint('  User: ${u.name}, Zone: "${u.zone}" -> matches: $matches');
      return matches;
    }).toList();
    debugPrint('Filtered pending users count: ${filtered.length}');
    return filtered;
  }

  List<UserModel> get approvedUsers {
    debugPrint('approvedUsers called. Total raw users: ${_approvedUsers.length}');
    if (_selectedZoneFilter == 'All Zones' || _selectedZoneFilter.isEmpty) {
      return _approvedUsers;
    }
    final targetZone = _selectedZoneFilter.trim().toLowerCase();
    debugPrint('Filtering approved users for selected zone filter: "$targetZone"');
    final filtered = _approvedUsers.where((u) {
      final userZone = u.zone?.trim().toLowerCase();
      if (userZone == null || userZone.isEmpty || userZone == 'null') {
        return true;
      }
      final matches = (userZone == targetZone) ||
          userZone.contains(targetZone) ||
          targetZone.contains(userZone);
      debugPrint('  User: ${u.name}, Zone: "${u.zone}" -> matches: $matches');
      return matches;
    }).toList();
    debugPrint('Filtered approved users count: ${filtered.length}');
    return filtered;
  }

  List<UserModel> get rejectedUsers {
    if (_selectedZoneFilter == 'All Zones' || _selectedZoneFilter.isEmpty) {
      return _rejectedUsers;
    }
    final targetZone = _selectedZoneFilter.trim().toLowerCase();
    return _rejectedUsers.where((u) {
      final userZone = u.zone?.trim().toLowerCase();
      if (userZone == null || userZone.isEmpty || userZone == 'null') {
        return true;
      }
      return (userZone == targetZone) ||
          userZone.contains(targetZone) ||
          targetZone.contains(userZone);
    }).toList();
  }
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

  /// Checks and restores the active admin session from local storage.
  Future<void> checkAdminSession() async {
    _setError(null);
    try {
      final jsonStr = _prefs.getString(_cachedAdminKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        _currentAdmin = AdminModel.fromJson(Map<String, dynamic>.from(decoded));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load cached admin session: $e');
    }
  }

  /// Logs in administrative credentials.
  Future<bool> loginAdmin(String username, String password, {String? allowedRole}) async {
    _setLoading(true);
    _setError(null);
    try {
      final admin = await _adminRepository.getAdminByUsername(username);
      if (admin != null && admin.password == password) {
        if (allowedRole != null && admin.role != allowedRole) {
          if (allowedRole == 'zonal_admin' && admin.role == 'super_admin') {
            _setError('Access denied: Please use the Super Admin login portal.');
          } else if (allowedRole == 'super_admin' && admin.role == 'zonal_admin') {
            _setError('Access denied: Please use the Zonal Admin login portal.');
          } else {
            _setError('Access denied: Unauthorized role.');
          }
          return false;
        }
        _currentAdmin = admin;
        
        // Cache admin session details locally
        final jsonStr = jsonEncode(admin.toJson());
        await _prefs.setString(_cachedAdminKey, jsonStr);

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
    _prefs.remove(_cachedAdminKey);
    notifyListeners();
  }

  /// Fetches pending registrations from database.
  Future<void> fetchPendingUsers() async {
    print('🚀 [AdminProvider] fetchPendingUsers() triggered');
    _setLoading(true);
    _setError(null);
    try {
      await _ensureAuthSession();
      _pendingUsers = await _adminRepository.getPendingUsers();
      print('📥 [AdminProvider] _pendingUsers populated with ${_pendingUsers.length} raw items.');
    } catch (e) {
      print('❌ [AdminProvider] fetchPendingUsers error: $e');
      _setError('Failed to fetch pending users: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Approves a registration request.
  Future<bool> approveUser(String uid) async {
    _setError(null);
    try {
      final reviewerName = _currentAdmin != null
          ? (_currentAdmin!.role == 'super_admin' ? 'Super Admin (${_currentAdmin!.username})' : '${_currentAdmin!.username} (Zonal Admin)')
          : 'Admin';
      final reviewerId = _currentAdmin?.username ?? 'admin';
      final reviewedAtStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      final userIndex = _pendingUsers.indexWhere((u) => u.uid == uid);
      String? assignedMembershipId;
      if (userIndex != -1) {
        final pendingUser = _pendingUsers[userIndex];
        assignedMembershipId = pendingUser.membershipId;
        if ((assignedMembershipId == null || assignedMembershipId.trim().isEmpty) &&
            pendingUser.zone != null &&
            pendingUser.zone!.isNotEmpty) {
          assignedMembershipId = await _adminRepository.generateNextMembershipId(pendingUser.zone!);
        }
      }

      await _adminRepository.updateUserStatus(
        uid, 
        'approved', 
        true,
        reviewedByName: reviewerName,
        reviewedById: reviewerId,
        reviewedAt: reviewedAtStr,
        membershipId: assignedMembershipId,
      );

      if (userIndex != -1) {
        final user = _pendingUsers[userIndex].copyWith(
          status: 'approved', 
          isApproved: true,
          reviewedByName: reviewerName,
          reviewedById: reviewerId,
          reviewedAt: reviewedAtStr,
          membershipId: assignedMembershipId ?? _pendingUsers[userIndex].membershipId,
        );
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
      final reviewerName = _currentAdmin != null
          ? (_currentAdmin!.role == 'super_admin' ? 'Super Admin (${_currentAdmin!.username})' : '${_currentAdmin!.username} (Zonal Admin)')
          : 'Admin';
      final reviewerId = _currentAdmin?.username ?? 'admin';
      final reviewedAtStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      await _adminRepository.updateUserStatus(
        uid, 
        'rejected', 
        false,
        reviewedByName: reviewerName,
        reviewedById: reviewerId,
        reviewedAt: reviewedAtStr,
      );
      final userIndex = _pendingUsers.indexWhere((u) => u.uid == uid);
      if (userIndex != -1) {
        final user = _pendingUsers[userIndex].copyWith(
          status: 'rejected', 
          isApproved: false,
          reviewedByName: reviewerName,
          reviewedById: reviewerId,
          reviewedAt: reviewedAtStr,
        );
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
    if (profileImageId.startsWith('http')) return;
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
      final fetched = await _adminRepository.getZones();
      final list = <String>[];
      if (!fetched.contains('Executive Committee')) {
        list.add('Executive Committee');
      }
      list.addAll(fetched);
      _zones = list;
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
