import '../../../../core/services/firestore_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirestoreService _firestoreService;

  NotificationRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> saveNotification(NotificationModel notification) async {
    await _firestoreService.saveNotification(notification);
  }

  Future<List<NotificationModel>> getNotifications() async {
    return await _firestoreService.getNotifications();
  }

  Future<void> deleteNotification(String id) async {
    await _firestoreService.deleteNotification(id);
  }
}
