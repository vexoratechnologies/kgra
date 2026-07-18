import '../../../../core/services/firestore_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../notification/data/models/notification_model.dart';
import '../models/event_model.dart';

class EventRepository {
  final FirestoreService _firestoreService;

  EventRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  Future<void> saveEvent(EventModel event) async {
    await _firestoreService.saveEvent(event);

    // Save system notification
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Event Scheduled',
      body: '${event.title} on ${event.date}',
      routingPath: AppRoutes.notification,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _firestoreService.saveNotification(notification);

    // Trigger push notification broadcast
    await PushNotificationService.instance.sendBroadcastNotification(
      title: 'New Event Scheduled',
      body: '${event.title} on ${event.date}',
      routingPath: AppRoutes.notification,
    );
  }

  Future<List<EventModel>> getEvents() async {
    return await _firestoreService.getEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _firestoreService.deleteEvent(id);
  }
}
