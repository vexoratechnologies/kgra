import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../features/events/data/models/event_model.dart';

/// FirestoreService manages CRUD actions in Cloud Firestore.
class FirestoreService {
  FirestoreService();

  FirebaseFirestore get _firestore {
    return FirebaseFirestore.instance;
  }

  // ==========================================
  // Public Service Actions
  // ==========================================

  /// Retrieves a user document by phone number.
  /// Returns null if user is not found.
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber) async {
    print(phoneNumber);
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
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(user.toJson());
  }

  /// Retrieves a user document by UID.
  Future<UserModel?> getUserByUid(String uid) async {
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
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .delete();
  }

  // ==========================================
  // Committee Members Management
  // ==========================================

  Future<void> saveCommitteeMember(String id, Map<String, dynamic> data) async {
    await _firestore
        .collection(FirestoreCollections.committeeMembers)
        .doc(id)
        .set(data);
  }

  Future<List<Map<String, dynamic>>> getCommitteeMembers() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.committeeMembers)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> deleteCommitteeMember(String id) async {
    await _firestore
        .collection(FirestoreCollections.committeeMembers)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Document Metadata Management (Using Firebase Storage for PDFs)
  // ==========================================

  Future<void> saveDocumentMetadata(String collectionName, String docId, Map<String, dynamic> metadata) async {
    await _firestore
        .collection(collectionName)
        .doc(docId)
        .set(metadata);
  }

  Future<List<Map<String, dynamic>>> getDocumentsList(String collectionName) async {
    final querySnapshot = await _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> deleteDocumentMetadata(String collectionName, String docId) async {
    await _firestore
        .collection(collectionName)
        .doc(docId)
        .delete();
  }

  // ==========================================
  // Admin & Zones Management
  // ==========================================

  Future<void> saveAdmin(AdminModel admin) async {
    await _firestore
        .collection(FirestoreCollections.admins)
        .doc(admin.username)
        .set(admin.toJson());
  }

  Future<AdminModel?> getAdminByUsername(String username) async {
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
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.admins)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => AdminModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteAdmin(String username) async {
    await _firestore
        .collection(FirestoreCollections.admins)
        .doc(username)
        .delete();
  }

  Future<void> saveZone(String name) async {
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
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
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.zones)
        .where('name', isEqualTo: name)
        .get();
    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ==========================================
  // Designations Management
  // ==========================================

  Future<void> saveDesignation(String name) async {
    final docId = DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore
        .collection(FirestoreCollections.designations)
        .doc(docId)
        .set({
          'id': docId,
          'name': name,
          'createdAt': docId,
        });
  }

  Future<List<String>> getDesignations() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.designations)
        .orderBy('createdAt', descending: false)
        .get();
    return querySnapshot.docs
        .map((doc) => doc.data()['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<void> deleteDesignation(String name) async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.designations)
        .where('name', isEqualTo: name)
        .get();
    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ==========================================
  // Zonal Committee Members Management
  // ==========================================

  Future<void> saveZonalMember(ZonalMemberModel member) async {
    await _firestore
        .collection(FirestoreCollections.zonalMembers)
        .doc(member.id)
        .set(member.toJson());
  }

  Future<List<ZonalMemberModel>> getZonalMembers() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.zonalMembers)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => ZonalMemberModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteZonalMember(String id) async {
    await _firestore
        .collection(FirestoreCollections.zonalMembers)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Updates Management
  // ==========================================

  Future<void> saveUpdate(UpdateModel update) async {
    await _firestore
        .collection(FirestoreCollections.updates)
        .doc(update.id)
        .set(update.toJson());
  }

  Future<List<UpdateModel>> getUpdates() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.updates)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => UpdateModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteUpdate(String id) async {
    await _firestore
        .collection(FirestoreCollections.updates)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Notifications Management
  // ==========================================

  Future<void> saveNotification(NotificationModel notification) async {
    await _firestore
        .collection(FirestoreCollections.notifications)
        .doc(notification.id)
        .set(notification.toJson());
  }

  Future<List<NotificationModel>> getNotifications() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.notifications)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => NotificationModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteNotification(String id) async {
    await _firestore
        .collection(FirestoreCollections.notifications)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Live Sessions Management
  // ==========================================

  Future<void> saveLiveSession(LiveSessionModel session) async {
    await _firestore
        .collection(FirestoreCollections.liveSessions)
        .doc(session.id)
        .set(session.toJson());
  }

  Future<List<LiveSessionModel>> getLiveSessions() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.liveSessions)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => LiveSessionModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteLiveSession(String id) async {
    await _firestore
        .collection(FirestoreCollections.liveSessions)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Gallery Management
  // ==========================================

  Future<void> saveGalleryImage(GalleryImageModel image) async {
    await _firestore
        .collection(FirestoreCollections.gallery)
        .doc(image.id)
        .set(image.toJson());
  }

  Future<List<GalleryImageModel>> getGalleryImages() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.gallery)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => GalleryImageModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteGalleryImage(String id) async {
    await _firestore
        .collection(FirestoreCollections.gallery)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Videos Management
  // ==========================================

  Future<void> saveVideo(VideoModel video) async {
    await _firestore
        .collection(FirestoreCollections.videos)
        .doc(video.id)
        .set(video.toJson());
  }

  Future<List<VideoModel>> getVideos() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.videos)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => VideoModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteVideo(String id) async {
    await _firestore
        .collection(FirestoreCollections.videos)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Video Progress Management
  // ==========================================

  Future<void> saveVideoProgress(VideoProgressModel progress) async {
    final docId = '${progress.userId}_${progress.videoId}';
    await _firestore
        .collection(FirestoreCollections.videoProgress)
        .doc(docId)
        .set(progress.toJson());
  }

  Future<VideoProgressModel?> getVideoProgress(String userId, String videoId) async {
    final docId = '${userId}_${videoId}';
    final doc = await _firestore
        .collection(FirestoreCollections.videoProgress)
        .doc(docId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return VideoProgressModel.fromJson(doc.data()!);
  }

  Future<List<VideoProgressModel>> getUserVideoProgress(String userId) async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.videoProgress)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.map((doc) => VideoProgressModel.fromJson(doc.data())).toList();
  }

  // ==========================================
  // Ads Management
  // ==========================================

  Future<void> saveAd(AdModel ad) async {
    await _firestore
        .collection(FirestoreCollections.ads)
        .doc(ad.id)
        .set(ad.toJson());
  }

  Future<List<AdModel>> getAds() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.ads)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => AdModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteAd(String id) async {
    await _firestore
        .collection(FirestoreCollections.ads)
        .doc(id)
        .delete();
  }

  // ==========================================
  // Events Management
  // ==========================================

  Future<void> saveEvent(EventModel event) async {
    await _firestore
        .collection(FirestoreCollections.events)
        .doc(event.id)
        .set(event.toJson());
  }

  Future<List<EventModel>> getEvents() async {
    final querySnapshot = await _firestore
        .collection(FirestoreCollections.events)
        .orderBy('date', descending: false)
        .get();
    return querySnapshot.docs.map((doc) => EventModel.fromJson(doc.data())).toList();
  }

  Future<void> deleteEvent(String id) async {
    await _firestore
        .collection(FirestoreCollections.events)
        .doc(id)
        .delete();
  }
}
