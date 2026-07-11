import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';
import 'injection.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely catch errors in case configurations are not yet generated)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Automatically establish an anonymous session on Web to prevent permission issues
    if (kIsWeb) {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        debugPrint('Established anonymous session on startup.');
      }
    }
  } catch (e) {
    debugPrint('Firebase not initialized: $e');
  }

  // Initialize Dependency Injection
  await initInjection();

  // Boot the application
  runApp(const App());
}
