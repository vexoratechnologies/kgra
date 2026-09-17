import 'package:flutter/foundation.dart';
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

    return UserModel.fromJson(querySnapshot.docs.first.data(), docId: querySnapshot.docs.first.id);
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

    return UserModel.fromJson(docSnapshot.data()!, docId: docSnapshot.id);
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
    print('====================================================');
    print('🔍 [FirestoreService] getPendingUsers() started');
    print('📂 Target Collection: "${FirestoreCollections.users}"');
    
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .where(FirestoreFields.status, isEqualTo: 'pending')
          .get();

      print('🔎 Direct Query where(status == "pending") returned ${querySnapshot.docs.length} docs.');
      for (var doc in querySnapshot.docs) {
        print('   -> Doc ID: ${doc.id}, Data: ${doc.data()}');
      }

      if (querySnapshot.docs.isNotEmpty) {
        final users = querySnapshot.docs
            .map((doc) => UserModel.fromJson(doc.data(), docId: doc.id))
            .toList();
        print('✅ Returning ${users.length} pending users from direct query.');
        return users;
      }
    } catch (e) {
      print('⚠️ getPendingUsers direct query error: $e');
    }

    // Fallback: fetch all user documents and filter in memory to catch casing/whitespace differences or missing status
    print('🔄 Fallback: Fetching ALL documents from "${FirestoreCollections.users}" collection...');
    final allDocsSnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .get();

    print('📊 Total raw documents found in "${FirestoreCollections.users}": ${allDocsSnapshot.docs.length}');
    for (var doc in allDocsSnapshot.docs) {
      final data = doc.data();
      print('   📄 Doc [${doc.id}]: name="${data['name']}", status="${data['status']}", isApproved=${data['isApproved']}, zone="${data['zone']}", phone="${data['phoneNumber']}"');
    }

    final filteredUsers = allDocsSnapshot.docs
        .map((doc) => UserModel.fromJson(doc.data(), docId: doc.id))
        .where((user) {
          final s = user.status.trim().toLowerCase();
          final isPending = (s == 'pending' || s.isEmpty || !user.isApproved) &&
                 s != 'approved' &&
                 s != 'rejected';
          print('   🔍 Filter evaluation for ${user.name} (${user.uid}): status="${user.status}", isApproved=${user.isApproved} -> match: $isPending');
          return isPending;
        })
        .toList();

    print('✅ Fallback returning ${filteredUsers.length} pending users.');
    print('====================================================');
    return filteredUsers;
  }

  /// Updates status and approval flag of a user request.
  Future<void> updateUserStatus(
    String uid, 
    String status, 
    bool isApproved, {
    String? reviewedByName,
    String? reviewedById,
    String? reviewedAt,
    String? membershipId,
  }) async {
    final Map<String, dynamic> data = {
      FirestoreFields.status: status,
      FirestoreFields.isApproved: isApproved,
    };
    if (reviewedByName != null) data['reviewedByName'] = reviewedByName;
    if (reviewedById != null) data['reviewedById'] = reviewedById;
    if (reviewedAt != null) data['reviewedAt'] = reviewedAt;
    if (membershipId != null && membershipId.isNotEmpty) data['membershipId'] = membershipId;

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .update(data);
  }

  /// Retrieves all users with a specific status.
  Future<List<UserModel>> getUsersByStatus(String status) async {
    final targetStatus = status.trim().toLowerCase();
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .where(FirestoreFields.status, isEqualTo: status)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs
            .map((doc) => UserModel.fromJson(doc.data(), docId: doc.id))
            .toList();
      }
    } catch (e) {
      print('getUsersByStatus direct query error: $e');
    }

    // Fallback: fetch all user documents and filter flexibly in memory
    final allDocsSnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .get();

    return allDocsSnapshot.docs
        .map((doc) => UserModel.fromJson(doc.data(), docId: doc.id))
        .where((user) {
          final s = user.status.trim().toLowerCase();
          if (targetStatus == 'approved') {
            return s == 'approved' || user.isApproved;
          } else if (targetStatus == 'rejected') {
            return s == 'rejected';
          } else if (targetStatus == 'pending') {
            return (s == 'pending' || s.isEmpty || !user.isApproved) &&
                   s != 'approved' &&
                   s != 'rejected';
          }
          return s == targetStatus;
        })
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

  Future<int> getNotificationsCount() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.notifications)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<List<NotificationModel>> getNotificationsPaged({
    required int limit,
    String? startAfterCreatedAt,
  }) async {
    Query query = _firestore
        .collection(FirestoreCollections.notifications)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfterCreatedAt != null && startAfterCreatedAt.isNotEmpty) {
      query = query.startAfter([startAfterCreatedAt]);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs
        .map((doc) => NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
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
        .get();
    final list = querySnapshot.docs.map((doc) => GalleryImageModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
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
        .get();
    final list = querySnapshot.docs.map((doc) => VideoModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
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
        .get();
    final list = querySnapshot.docs.map((doc) => AdModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
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

  // ==========================================
  // Membership ID Counter & Prefix Management
  // ==========================================

  /// Returns the zone prefix and short code for a given zone name.
  /// E.g. "Trivandrum" -> { code: 'TVM', prefix: 'KGRATVM/' }
  static Map<String, String> getZoneDetails(String? zone) {
    if (zone == null || zone.trim().isEmpty) {
      return {'code': 'GEN', 'prefix': 'KGRA/'};
    }
    final clean = zone.trim().toLowerCase();
    String code;
    if (clean.contains('trivandrum') || clean.contains('thiruvananthapuram') || clean == 'tvm') {
      code = 'TVM';
    } else if (clean.contains('kollam') || clean == 'klm') {
      code = 'KLM';
    } else if (clean.contains('pathanamthitta') || clean == 'pta') {
      code = 'PTA';
    } else if (clean.contains('alappuzha') || clean == 'alp') {
      code = 'ALP';
    } else if (clean.contains('kottayam') || clean == 'ktm') {
      code = 'KTM';
    } else if (clean.contains('idukki') || clean == 'idk') {
      code = 'IDK';
    } else if (clean.contains('ernakulam') || clean.contains('kochi') || clean == 'ekm') {
      code = 'EKM';
    } else if (clean.contains('thrissur') || clean == 'tcr') {
      code = 'TCR';
    } else if (clean.contains('palakkad') || clean == 'pkd') {
      code = 'PKD';
    } else if (clean.contains('malappuram') || clean == 'mpm') {
      code = 'MPM';
    } else if (clean.contains('kozhikode') || clean == 'kkd') {
      code = 'KKD';
    } else if (clean.contains('wayanad') || clean == 'wyd') {
      code = 'WYD';
    } else if (clean.contains('kannur') || clean == 'knr') {
      code = 'KNR';
    } else if (clean.contains('kasaragod') || clean == 'ksd') {
      code = 'KSD';
    } else {
      final alphaOnly = zone.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
      if (alphaOnly.length >= 3) {
        code = alphaOnly.substring(0, 3);
      } else if (alphaOnly.isNotEmpty) {
        code = alphaOnly.padRight(3, 'X');
      } else {
        code = 'GEN';
      }
    }
    return {'code': code, 'prefix': 'KGRA$code/'};
  }

  /// Read-only preview of the next membership ID for a zone without incrementing.
  /// Uses a shared global sequential counter across all zones.
  Future<String> peekNextMembershipId(String zone) async {
    final details = getZoneDetails(zone);
    final prefix = details['prefix']!;

    try {
      final docSnapshot = await _firestore
          .collection(FirestoreCollections.counters)
          .doc('zone_counters')
          .get();

      int currentCount = 0;
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        currentCount = (data['global_counter'] as num?)?.toInt() ?? 0;
      }

      if (currentCount == 0) {
        currentCount = await _findMaxMembershipSeqFromUsers();
      }

      final nextSeq = currentCount + 1;
      return '$prefix${nextSeq.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Error peeking next membership ID: $e');
      final fallbackSeq = (await _findMaxMembershipSeqFromUsers()) + 1;
      return '$prefix${fallbackSeq.toString().padLeft(2, '0')}';
    }
  }

  /// Atomically increments and returns the next membership ID using a shared global sequence across all zones.
  Future<String> generateNextMembershipId(String zone) async {
    final details = getZoneDetails(zone);
    final prefix = details['prefix']!;
    final docRef = _firestore
        .collection(FirestoreCollections.counters)
        .doc('zone_counters');

    try {
      final nextSeq = await _firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(docRef);
        int currentCount = 0;
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          currentCount = (data['global_counter'] as num?)?.toInt() ?? 0;
        }

        if (currentCount == 0) {
          currentCount = await _findMaxMembershipSeqFromUsers();
        }

        final newCount = currentCount + 1;
        transaction.set(
          docRef,
          {'global_counter': newCount},
          SetOptions(merge: true),
        );
        return newCount;
      });

      return '$prefix${nextSeq.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Error generating next membership ID in transaction: $e');
      final fallbackSeq = (await _findMaxMembershipSeqFromUsers()) + 1;
      return '$prefix${fallbackSeq.toString().padLeft(2, '0')}';
    }
  }

  /// Internal helper to find highest numeric sequence from USERS collection across all zones
  Future<int> _findMaxMembershipSeqFromUsers() async {
    try {
      final usersSnap = await _firestore.collection(FirestoreCollections.users).get();
      int maxNum = 0;
      final regExp = RegExp(r'(\d+)$');
      for (final doc in usersSnap.docs) {
        final memId = doc.data()['membershipId'] as String?;
        if (memId != null && memId.isNotEmpty) {
          final match = regExp.firstMatch(memId);
          if (match != null) {
            final numVal = int.tryParse(match.group(1) ?? '');
            if (numVal != null && numVal > maxNum) {
              maxNum = numVal;
            }
          }
        }
      }
      return maxNum;
    } catch (_) {
      return 0;
    }
  }
}
