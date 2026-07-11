import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/firestore_constants.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/models/admin_model.dart';
import '../../features/zonal/data/models/zonal_member_model.dart';
import '../../features/updates/data/models/update_model.dart';
import '../../features/notification/data/models/notification_model.dart';
import '../../features/live_sessions/data/models/live_session_model.dart';
import '../../features/videos/data/models/video_model.dart';
import '../../features/videos/data/models/video_progress_model.dart';
import '../../features/gallery/data/models/gallery_image_model.dart';
import '../../features/ads/data/models/ad_model.dart';

/// FirestoreService manages CRUD actions in Cloud Firestore.
/// 
/// If Firebase is not initialized, it automatically falls back to a SharedPreferences-backed
/// mock database to allow offline local testing and layout previews without crashing.
class FirestoreService {
  final SharedPreferences _prefs;

  FirestoreService({required SharedPreferences prefs}) : _prefs = prefs;
  
  bool get _useMock => Firebase.apps.isEmpty;

  FirebaseFirestore get _firestore {
    return FirebaseFirestore.instance;
  }

  // ==========================================
  // SharedPreferences Mock Database Helpers
  // ==========================================
  
  static const String _mockUsersKey = 'mock_firestore_users';

  Future<List<UserModel>> _getMockUsers() async {
    final jsonStr = _prefs.getString(_mockUsersKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => UserModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockUsers(List<UserModel> users) async {
    final jsonStr = jsonEncode(users.map((u) => u.toJson()).toList());
    await _prefs.setString(_mockUsersKey, jsonStr);
  }

  // ==========================================
  // Public Service Actions
  // ==========================================

  /// Retrieves a user document by phone number.
  /// Returns null if user is not found.
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (_useMock) {
      final users = await _getMockUsers();
      try {
        return users.firstWhere(
          (u) => u.phoneNumber.replaceAll(RegExp(r'\D'), '') == cleanPhone,
        );
      } catch (_) {
        return null;
      }
    }

    final querySnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where(FirestoreFields.phoneNumber, isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return UserModel.fromJson(querySnapshot.docs.first.data());
  }

  /// Saves a UserModel inside the USERS collection.
  Future<void> saveUser(UserModel user) async {
    if (_useMock) {
      final users = await _getMockUsers();
      // Remove existing if any
      users.removeWhere((u) => u.uid == user.uid || u.phoneNumber == user.phoneNumber);
      users.add(user);
      await _saveMockUsers(users);
      return;
    }

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(user.toJson());
  }

  /// Retrieves a user document by UID.
  Future<UserModel?> getUserByUid(String uid) async {
    if (_useMock) {
      final users = await _getMockUsers();
      try {
        return users.firstWhere((u) => u.uid == uid);
      } catch (_) {
        return null;
      }
    }

    final docSnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }

    return UserModel.fromJson(docSnapshot.data()!);
  }

  /// Checks if a phone number is registered.
  Future<bool> userExists(String phoneNumber) async {
    final user = await getUserByPhoneNumber(phoneNumber);
    return user != null;
  }

  /// Saves a compressed base64 profile image inside the USER_IMAGES collection.
  Future<void> saveUserImage(String profileImageId, String imageBase64) async {
    if (_useMock) {
      final key = 'mock_user_image_$profileImageId';
      final Map<String, dynamic> data = {
        'uid': profileImageId,
        'imageBase64': imageBase64,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await _prefs.setString(key, jsonEncode(data));
      return;
    }

    await _firestore
        .collection(FirestoreCollections.userImages)
        .doc(profileImageId)
        .set({
          'uid': profileImageId,
          'imageBase64': imageBase64,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Retrieves a profile image document by profileImageId.
  Future<Map<String, dynamic>?> getUserImage(String profileImageId) async {
    if (_useMock) {
      final key = 'mock_user_image_$profileImageId';
      final jsonStr = _prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    final docSnapshot = await _firestore
        .collection(FirestoreCollections.userImages)
        .doc(profileImageId)
        .get();

    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }

    final data = docSnapshot.data()!;
    final dynamic updatedAtRaw = data['updatedAt'];
    String updatedAtStr = DateTime.now().toIso8601String();
    if (updatedAtRaw is Timestamp) {
      updatedAtStr = updatedAtRaw.toDate().toIso8601String();
    } else if (updatedAtRaw is String) {
      updatedAtStr = updatedAtRaw;
    }

    return {
      'uid': data['uid'] as String? ?? profileImageId,
      'imageBase64': data['imageBase64'] as String? ?? '',
      'updatedAt': updatedAtStr,
    };
  }

  /// Retrieves all users with 'pending' status.
  Future<List<UserModel>> getPendingUsers() async {
    if (_useMock) {
      final users = await _getMockUsers();
      return users.where((u) => u.status == 'pending').toList();
    }

    final querySnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where(FirestoreFields.status, isEqualTo: 'pending')
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }

  /// Updates status and approval flag of a user request.
  Future<void> updateUserStatus(String uid, String status, bool isApproved) async {
    if (_useMock) {
      final users = await _getMockUsers();
      final index = users.indexWhere((u) => u.uid == uid);
      if (index != -index) {
        final updatedUser = users[index].copyWith(
          status: status,
          isApproved: isApproved,
        );
        users[index] = updatedUser;
        await _saveMockUsers(users);
      }
      return;
    }

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .update({
          FirestoreFields.status: status,
          FirestoreFields.isApproved: isApproved,
        });
  }

  /// Retrieves all users with a specific status.
  Future<List<UserModel>> getUsersByStatus(String status) async {
    if (_useMock) {
      final users = await _getMockUsers();
      return users.where((u) => u.status == status).toList();
    }

    final querySnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where(FirestoreFields.status, isEqualTo: status)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }

  /// Deletes a user document by UID.
  Future<void> deleteUser(String uid) async {
    if (_useMock) {
      final users = await _getMockUsers();
      users.removeWhere((u) => u.uid == uid);
      await _saveMockUsers(users);
      return;
    }

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .delete();
  }

  // ==========================================
  // Committee Members Management
  // ==========================================

  static const String _mockCommitteeMembersKey = 'mock_firestore_committee_members';

  Future<List<Map<String, dynamic>>> _getMockCommitteeMembers() async {
    final jsonStr = _prefs.getString(_mockCommitteeMembersKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockCommitteeMembers(List<Map<String, dynamic>> list) async {
    final jsonStr = jsonEncode(list);
    await _prefs.setString(_mockCommitteeMembersKey, jsonStr);
  }

  Future<void> saveCommitteeMember(String id, Map<String, dynamic> data) async {
    if (_useMock) {
      final list = await _getMockCommitteeMembers();
      list.removeWhere((item) => item['id'] == id);
      list.add(data);
      await _saveMockCommitteeMembers(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.committeeMembers)
        .doc(id)
        .set(data);
  }

  Future<List<Map<String, dynamic>>> getCommitteeMembers() async {
    if (_useMock) {
      final list = await _getMockCommitteeMembers();
      list.sort((a, b) {
        final aDate = a['createdAt'] as String? ?? '';
        final bDate = b['createdAt'] as String? ?? '';
        return bDate.compareTo(aDate);
      });
      return list;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.committeeMembers)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> deleteCommitteeMember(String id) async {
    if (_useMock) {
      final list = await _getMockCommitteeMembers();
      list.removeWhere((item) => item['id'] == id);
      await _saveMockCommitteeMembers(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.committeeMembers)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Document Metadata Management (Using Firebase Storage for PDFs)
  // ==========================================

  Future<void> saveDocumentMetadata(String collectionName, String docId, Map<String, dynamic> metadata) async {
    if (_useMock) {
      await _prefs.setString('mock_${collectionName}_$docId', jsonEncode(metadata));
      return;
    }
    await _firestore
        .collection(collectionName)
        .doc(docId)
        .set(metadata);
  }

  Future<List<Map<String, dynamic>>> getDocumentsList(String collectionName) async {
    if (_useMock) {
      final keys = _prefs.getKeys();
      final prefix = 'mock_${collectionName}_';
      final List<Map<String, dynamic>> list = [];
      for (final key in keys) {
        if (key.startsWith(prefix)) {
          final jsonStr = _prefs.getString(key);
          if (jsonStr != null) {
            final metadata = jsonDecode(jsonStr) as Map<String, dynamic>;
            list.add(metadata);
          }
        }
      }
      list.sort((a, b) {
        final aDate = a['createdAt'] as String? ?? '';
        final bDate = b['createdAt'] as String? ?? '';
        return bDate.compareTo(aDate); // Descending
      });
      return list;
    }

    final querySnapshot = await _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> deleteDocumentMetadata(String collectionName, String docId) async {
    if (_useMock) {
      await _prefs.remove('mock_${collectionName}_$docId');
      return;
    }
    await _firestore
        .collection(collectionName)
        .doc(docId)
        .delete();
  }

  // ==========================================
  // Admin & Zones Management
  // ==========================================

  static const String _mockAdminsKey = 'mock_firestore_admins';
  static const String _mockZonesKey = 'mock_firestore_zones';

  Future<List<AdminModel>> _getMockAdmins() async {
    final jsonStr = _prefs.getString(_mockAdminsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => AdminModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockAdmins(List<AdminModel> adminsList) async {
    final jsonStr = jsonEncode(adminsList.map((a) => a.toJson()).toList());
    await _prefs.setString(_mockAdminsKey, jsonStr);
  }

  Future<void> saveAdmin(AdminModel admin) async {
    if (_useMock) {
      final adminsList = await _getMockAdmins();
      adminsList.removeWhere((a) => a.username == admin.username);
      adminsList.add(admin);
      await _saveMockAdmins(adminsList);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.admins)
        .doc(admin.username)
        .set(admin.toJson());
  }

  Future<AdminModel?> getAdminByUsername(String username) async {
    if (_useMock) {
      final adminsList = await _getMockAdmins();
      try {
        return adminsList.firstWhere((a) => a.username == username);
      } catch (_) {
        return null;
      }
    }
    final docSnapshot = await _firestore
        .collection(FirestoreCollections.admins)
        .doc(username)
        .get();
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }
    return AdminModel.fromJson(docSnapshot.data()!);
  }

  Future<List<AdminModel>> getAdmins() async {
    if (_useMock) {
      return await _getMockAdmins();
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.admins)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => AdminModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteAdmin(String username) async {
    if (_useMock) {
      final adminsList = await _getMockAdmins();
      adminsList.removeWhere((a) => a.username == username);
      await _saveMockAdmins(adminsList);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.admins)
        .doc(username)
        .delete();
  }

  Future<List<String>> _getMockZones() async {
    final jsonStr = _prefs.getString(_mockZonesKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return ['North Zone', 'South Zone', 'Central Zone'];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockZones(List<String> zonesList) async {
    final jsonStr = jsonEncode(zonesList);
    await _prefs.setString(_mockZonesKey, jsonStr);
  }

  Future<void> saveZone(String name) async {
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    if (_useMock) {
      final zonesList = await _getMockZones();
      if (!zonesList.contains(name)) {
        zonesList.add(name);
        await _saveMockZones(zonesList);
      }
      return;
    }
    await _firestore
        .collection(FirestoreCollections.zones)
        .doc(docId)
        .set({
          'id': docId,
          'name': name,
          'createdAt': docId,
        });
  }

  Future<List<String>> getZones() async {
    if (_useMock) {
      return await _getMockZones();
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.zones)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs
        .map((doc) => doc.data()['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<void> deleteZone(String name) async {
    if (_useMock) {
      final zonesList = await _getMockZones();
      zonesList.removeWhere((z) => z == name);
      await _saveMockZones(zonesList);
      return;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.zones)
        .where('name', isEqualTo: name)
        .get();
    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ==========================================
  // Zonal Committee Members Management
  // ==========================================

  static const String _mockZonalMembersKey = 'mock_firestore_zonal_members';

  Future<List<ZonalMemberModel>> _getMockZonalMembers() async {
    final jsonStr = _prefs.getString(_mockZonalMembersKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => ZonalMemberModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockZonalMembers(List<ZonalMemberModel> list) async {
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs.setString(_mockZonalMembersKey, jsonStr);
  }

  Future<void> saveZonalMember(ZonalMemberModel member) async {
    if (_useMock) {
      final list = await _getMockZonalMembers();
      list.removeWhere((item) => item.id == member.id);
      list.add(member);
      await _saveMockZonalMembers(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.zonalMembers)
        .doc(member.id)
        .set(member.toJson());
  }

  Future<List<ZonalMemberModel>> getZonalMembers() async {
    if (_useMock) {
      final list = await _getMockZonalMembers();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.zonalMembers)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => ZonalMemberModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteZonalMember(String id) async {
    if (_useMock) {
      final list = await _getMockZonalMembers();
      list.removeWhere((item) => item.id == id);
      await _saveMockZonalMembers(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.zonalMembers)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Updates Management
  // ==========================================

  static const String _mockUpdatesKey = 'mock_firestore_updates';

  Future<List<UpdateModel>> _getMockUpdates() async {
    final jsonStr = _prefs.getString(_mockUpdatesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => UpdateModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockUpdates(List<UpdateModel> list) async {
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs.setString(_mockUpdatesKey, jsonStr);
  }

  Future<void> saveUpdate(UpdateModel update) async {
    if (_useMock) {
      final list = await _getMockUpdates();
      list.removeWhere((item) => item.id == update.id);
      list.add(update);
      await _saveMockUpdates(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.updates)
        .doc(update.id)
        .set(update.toJson());
  }

  Future<List<UpdateModel>> getUpdates() async {
    if (_useMock) {
      final list = await _getMockUpdates();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.updates)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => UpdateModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteUpdate(String id) async {
    if (_useMock) {
      final list = await _getMockUpdates();
      list.removeWhere((item) => item.id == id);
      await _saveMockUpdates(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.updates)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Notifications Management
  // ==========================================

  static const String _mockNotificationsKey = 'mock_firestore_notifications';

  Future<List<NotificationModel>> _getMockNotifications() async {
    final jsonStr = _prefs.getString(_mockNotificationsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockNotifications(List<NotificationModel> list) async {
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs.setString(_mockNotificationsKey, jsonStr);
  }

  Future<void> saveNotification(NotificationModel notification) async {
    if (_useMock) {
      final list = await _getMockNotifications();
      list.removeWhere((item) => item.id == notification.id);
      list.add(notification);
      await _saveMockNotifications(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.notifications)
        .doc(notification.id)
        .set(notification.toJson());
  }

  Future<List<NotificationModel>> getNotifications() async {
    if (_useMock) {
      final list = await _getMockNotifications();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.notifications)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => NotificationModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteNotification(String id) async {
    if (_useMock) {
      final list = await _getMockNotifications();
      list.removeWhere((item) => item.id == id);
      await _saveMockNotifications(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.notifications)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Live Sessions Management
  // ==========================================

  static const String _mockLiveSessionsKey = 'mock_firestore_live_sessions';

  Future<List<LiveSessionModel>> _getMockLiveSessions() async {
    final jsonStr = _prefs.getString(_mockLiveSessionsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => LiveSessionModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockLiveSessions(List<LiveSessionModel> list) async {
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs.setString(_mockLiveSessionsKey, jsonStr);
  }

  Future<void> saveLiveSession(LiveSessionModel session) async {
    if (_useMock) {
      final list = await _getMockLiveSessions();
      list.removeWhere((item) => item.id == session.id);
      list.add(session);
      await _saveMockLiveSessions(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.liveSessions)
        .doc(session.id)
        .set(session.toJson());
  }

  Future<List<LiveSessionModel>> getLiveSessions() async {
    if (_useMock) {
      final list = await _getMockLiveSessions();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.liveSessions)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => LiveSessionModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteLiveSession(String id) async {
    if (_useMock) {
      final list = await _getMockLiveSessions();
      list.removeWhere((item) => item.id == id);
      await _saveMockLiveSessions(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.liveSessions)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Gallery Management
  // ==========================================

  static const String _mockGalleryKey = 'mock_firestore_gallery';

  Future<List<GalleryImageModel>> _getMockGallery() async {
    final jsonStr = _prefs.getString(_mockGalleryKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => GalleryImageModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockGallery(List<GalleryImageModel> list) async {
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs.setString(_mockGalleryKey, jsonStr);
  }

  Future<void> saveGalleryImage(GalleryImageModel image) async {
    if (_useMock) {
      final list = await _getMockGallery();
      list.removeWhere((item) => item.id == image.id);
      list.add(image);
      await _saveMockGallery(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.gallery)
        .doc(image.id)
        .set(image.toJson());
  }

  Future<List<GalleryImageModel>> getGalleryImages() async {
    if (_useMock) {
      final list = await _getMockGallery();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.gallery)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => GalleryImageModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteGalleryImage(String id) async {
    if (_useMock) {
      final list = await _getMockGallery();
      list.removeWhere((item) => item.id == id);
      await _saveMockGallery(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.gallery)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Videos Management
  // ==========================================

  static const String _mockVideosKey = 'mock_firestore_videos';
  static const String _mockVideoProgressKey = 'mock_firestore_video_progress';

  Future<List<VideoModel>> _getMockVideos() async {
    final jsonStr = _prefs.getString(_mockVideosKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => VideoModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockVideos(List<VideoModel> list) async {
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs.setString(_mockVideosKey, jsonStr);
  }

  Future<void> saveVideo(VideoModel video) async {
    if (_useMock) {
      final list = await _getMockVideos();
      list.removeWhere((item) => item.id == video.id);
      list.add(video);
      await _saveMockVideos(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.videos)
        .doc(video.id)
        .set(video.toJson());
  }

  Future<List<VideoModel>> getVideos() async {
    if (_useMock) {
      final list = await _getMockVideos();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.videos)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => VideoModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteVideo(String id) async {
    if (_useMock) {
      final list = await _getMockVideos();
      list.removeWhere((item) => item.id == id);
      await _saveMockVideos(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.videos)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Video Progress Management
  // ==========================================

  Future<List<VideoProgressModel>> _getMockVideoProgressList() async {
    final jsonStr = _prefs.getString(_mockVideoProgressKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => VideoProgressModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockVideoProgressList(List<VideoProgressModel> list) async {
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs.setString(_mockVideoProgressKey, jsonStr);
  }

  Future<void> saveVideoProgress(VideoProgressModel progress) async {
    final docId = '${progress.userId}_${progress.videoId}';
    if (_useMock) {
      final list = await _getMockVideoProgressList();
      list.removeWhere((item) => item.userId == progress.userId && item.videoId == progress.videoId);
      list.add(progress);
      await _saveMockVideoProgressList(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.videoProgress)
        .doc(docId)
        .set(progress.toJson());
  }

  Future<VideoProgressModel?> getVideoProgress(String userId, String videoId) async {
    if (_useMock) {
      final list = await _getMockVideoProgressList();
      try {
        return list.firstWhere((item) => item.userId == userId && item.videoId == videoId);
      } catch (_) {
        return null;
      }
    }
    final docId = '${userId}_${videoId}';
    final doc = await _firestore
        .collection(FirestoreCollections.videoProgress)
        .doc(docId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return VideoProgressModel.fromJson(doc.data()!);
  }

  Future<List<VideoProgressModel>> getUserVideoProgress(String userId) async {
    if (_useMock) {
      final list = await _getMockVideoProgressList();
      return list.where((item) => item.userId == userId).toList();
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.videoProgress)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.map((doc) => VideoProgressModel.fromJson(doc.data())).toList();
  }

  // ==========================================
  // Ads Management
  // ==========================================

  static const String _mockAdsKey = 'mock_firestore_ads';

  Future<List<AdModel>> _getMockAds() async {
    final jsonStr = _prefs.getString(_mockAdsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => AdModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMockAds(List<AdModel> list) async {
    final jsonStr = jsonEncode(list.map((item) => item.toJson()).toList());
    await _prefs.setString(_mockAdsKey, jsonStr);
  }

  Future<void> saveAd(AdModel ad) async {
    if (_useMock) {
      final list = await _getMockAds();
      list.removeWhere((item) => item.id == ad.id);
      list.add(ad);
      await _saveMockAds(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.ads)
        .doc(ad.id)
        .set(ad.toJson());
  }

  Future<List<AdModel>> getAds() async {
    if (_useMock) {
      final list = await _getMockAds();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.ads)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => AdModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteAd(String id) async {
    if (_useMock) {
      final list = await _getMockAds();
      list.removeWhere((item) => item.id == id);
      await _saveMockAds(list);
      return;
    }
    await _firestore
        .collection(FirestoreCollections.ads)
        .doc(id)
        .delete();
  }
}
