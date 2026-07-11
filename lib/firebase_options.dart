// File generated for Firebase config.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return null; // Let native configuration handle Android/iOS
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCy0gABYfKRIXv3ZO51dlI2RVitaRGAKF4",
    authDomain: "kgra-ba502.firebaseapp.com",
    databaseURL: "https://kgra-ba502-default-rtdb.firebaseio.com",
    projectId: "kgra-ba502",
    storageBucket: "kgra-ba502.firebasestorage.app",
    messagingSenderId: "922708808396",
    appId: "1:922708808396:web:8e888703f7b49fd9716869",
    measurementId: "G-K1T51GCCR7",
  );
}
