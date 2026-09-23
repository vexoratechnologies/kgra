// File generated for Firebase config.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBfPup4nYLkejFDe9vUueRpVlQGy1sVj_g",
    appId: "1:922708808396:android:4c4f46130e05fc8d716869",
    messagingSenderId: "922708808396",
    projectId: "kgra-ba502",
    databaseURL: "https://kgra-ba502-default-rtdb.firebaseio.com",
    storageBucket: "kgra-ba502.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBSYuyIwpsFAJmYRiPhmgIdfHAKJ981A0g",
    appId: "1:922708808396:ios:08be48ff8ba28eb8716869",
    messagingSenderId: "922708808396",
    projectId: "kgra-ba502",
    databaseURL: "https://kgra-ba502-default-rtdb.firebaseio.com",
    storageBucket: "kgra-ba502.firebasestorage.app",
    iosBundleId: "com.vexora.kgra",
  );
}
