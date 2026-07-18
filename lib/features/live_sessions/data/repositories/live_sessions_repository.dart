import '../../../../core/services/firestore_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../notification/data/models/notification_model.dart';
import '../models/live_session_model.dart';

class LiveSessionRepository {
  final FirestoreService _firestoreService;

  LiveSessionRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> saveLiveSession(LiveSessionModel session) async {
    await _firestoreService.saveLiveSession(session);

    // Save system notification
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Live Session Scheduled',
      body: '${session.title} has been scheduled.',
      routingPath: AppRoutes.liveSessions,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _firestoreService.saveNotification(notification);

    // Trigger push notification broadcast
    await PushNotificationService.instance.sendBroadcastNotification(
      title: 'New Live Session Scheduled',
      body: '${session.title} has been scheduled.',
      routingPath: AppRoutes.liveSessions,
    );
  }

  Future<List<LiveSessionModel>> getLiveSessions() async {
    return await _firestoreService.getLiveSessions();
  }

  Future<void> deleteLiveSession(String id) async {
    await _firestoreService.deleteLiveSession(id);
  }
}
