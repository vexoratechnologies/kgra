import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/services/push_notification_service.dart';
import 'core/update/app_version_service.dart';
import 'app.dart';
import 'injection.dart';
import 'firebase_options.dart';

void main() async {
  // Use path URL strategy for clean routing (removes hash '#' from URL)
  usePathUrlStrategy();
  
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initializeApp notice: $e');
  }

  // Initialize Remote App Lock & Version Checker independently (must run even if push fails)
  try {
    await AppVersionService.instance.init();
    AppVersionService.instance.startVersionListener();
  } catch (e) {
    debugPrint('AppVersionService init notice: $e');
  }

  // Initialize Push Notifications safely in separate try-catch so APNs/FCM errors never block version lock
  try {
    await PushNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('PushNotificationService init notice: $e');
  }

  // Establish an anonymous session in background without blocking initial frame
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      auth.signInAnonymously().then((_) {
        debugPrint('Established anonymous session on startup.');
      }).catchError((e) {
        debugPrint('Startup anonymous auth error: $e');
      });
    }
  } catch (e) {
    debugPrint('FirebaseAuth notice: $e');
  }

  // Initialize Dependency Injection
  await initInjection();

  // Boot the application
  runApp(const App());
}
