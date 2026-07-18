import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../routes/app_routes.dart';

/// PushNotificationService manages Firebase Cloud Messaging (FCM) configurations,
/// subscriptions, permission requests, and user click actions.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Initializes the service: requests permission, gets tokens, subscribes to topic,
  /// and listens to background/foreground/terminated notifications.
  Future<void> initialize() async {
    try {
      // 1. Request notifications permission (important for iOS and Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // 2. Configure foreground notification presentation options
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 3. Subscribe all users to the global topic to receive broadcasts
        await _fcm.subscribeToTopic('kgra_notifications');
        debugPrint('Subscribed to kgra_notifications topic.');
      }

      // 4. Retrieve and print FCM Token for debugging/targeting individual users
      String? token = await _fcm.getToken();
      debugPrint('FCM Device Token: $token');

      // 5. Handle notification click when the app was in background/suspended state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked from background/resume state.');
        _handleMessageClick(message);
      });

      // 6. Handle notification click when the app was in a terminated state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('Notification clicked from terminated state.');
        _handleMessageClick(initialMessage);
      }
    } catch (e) {
      debugPrint('Failed to initialize PushNotificationService: $e');
    }
  }

  /// Extracts routingPath data payload and performs navigation using GoRouter.
  void _handleMessageClick(RemoteMessage message) {
    debugPrint('FCM Message Data Payload: ${message.data}');
    final routingPath = message.data['routingPath'];
    if (routingPath != null && routingPath.toString().isNotEmpty) {
      final path = routingPath.toString();
      debugPrint('Navigating directly to path from notification click: $path');
      
      // Delay navigation slightly to ensure router config is fully initialized on cold launches
      Future.delayed(const Duration(milliseconds: 500), () {
        AppRoutes.router.push(path);
      });
    }
  }

  /// Sends a broadcast push notification to the 'kgra_notifications' topic via HTTP.
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    required String routingPath,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=YOUR_FCM_SERVER_KEY', // <-- REPLACE WITH YOUR ACTUAL SERVER KEY
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'routingPath': routingPath,
            },
            'to': '/topics/kgra_notifications',
          },
        ),
      );
      debugPrint('FCM HTTP send response: status=${response.statusCode}, body=${response.body}');
    } catch (e) {
      debugPrint('Error sending FCM HTTP push notification: $e');
    }
  }
}
