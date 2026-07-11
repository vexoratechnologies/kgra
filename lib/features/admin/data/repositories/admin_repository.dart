import '../../../../core/services/firestore_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/models/admin_model.dart';

/// AdminRepository orchestrates data transactions for administrative tasks.
class AdminRepository {
  final FirestoreService _firestoreService;

  AdminRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Retrieves list of all pending users.
  Future<List<UserModel>> getPendingUsers() async {
    return await _firestoreService.getPendingUsers();
  }

  /// Updates status and approval status for user.
  Future<void> updateUserStatus(String uid, String status, bool isApproved) async {
    await _firestoreService.updateUserStatus(uid, status, isApproved);
  }

  /// Retrieves user image details by profileImageId.
  Future<Map<String, dynamic>?> getUserImage(String profileImageId) async {
    return await _firestoreService.getUserImage(profileImageId);
  }

  /// Retrieves list of users by status.
  Future<List<UserModel>> getUsersByStatus(String status) async {
    return await _firestoreService.getUsersByStatus(status);
  }

  // ==========================================
  // Admin & Zones Management
  // ==========================================

  Future<AdminModel?> getAdminByUsername(String username) async {
    return await _firestoreService.getAdminByUsername(username);
  }

  Future<void> saveAdmin(AdminModel admin) async {
    await _firestoreService.saveAdmin(admin);
  }

  Future<List<AdminModel>> getAdmins() async {
    return await _firestoreService.getAdmins();
  }

  Future<void> deleteAdmin(String username) async {
    await _firestoreService.deleteAdmin(username);
  }

  Future<List<String>> getZones() async {
    return await _firestoreService.getZones();
  }

  Future<void> saveZone(String name) async {
    await _firestoreService.saveZone(name);
  }

  Future<void> deleteZone(String name) async {
    await _firestoreService.deleteZone(name);
  }
}
