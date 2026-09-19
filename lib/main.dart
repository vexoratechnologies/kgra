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

  // Initialize Firebase (safely catch errors in case configurations are not yet generated)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Push Notifications
    await PushNotificationService.instance.initialize();

    // Establish an anonymous session in background without blocking initial frame
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      auth.signInAnonymously().then((_) {
        debugPrint('Established anonymous session on startup.');
      }).catchError((e) {
        debugPrint('Startup anonymous auth error: $e');
      });
    }

    // Initialize Remote App Lock & Version Checker
    await AppVersionService.instance.init();
    AppVersionService.instance.startVersionListener(
      rootNode: '0',
    );
  } catch (e) {
    debugPrint('Firebase not initialized: $e');
  }

  // Initialize Dependency Injection
  await initInjection();

  // Boot the application
  runApp(const App());
}
