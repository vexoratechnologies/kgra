import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Configuration data for the force update screen
class ForceUpdateConfig {
  final String message;
  final String buttonText;
  final String storeUrl;

  const ForceUpdateConfig({
    required this.message,
    required this.buttonText,
    required this.storeUrl,
  });
}

/// Singleton service responsible for monitoring app version permissions
/// and enforcing remote app lock / force update via Firebase Realtime Database.
class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  static const String defaultDatabaseUrl = 'https://kgra-ba502-default-rtdb.firebaseio.com';

  PackageInfo? _packageInfo;
  StreamSubscription<DatabaseEvent>? _versionSubscription;

  /// Reactive notifier for current lock configuration.
  /// When not null, the app must display the force update lock screen.
  final ValueNotifier<ForceUpdateConfig?> updateConfigNotifier = ValueNotifier<ForceUpdateConfig?>(null);

  /// Cached package information
  PackageInfo? get packageInfo => _packageInfo;

  /// Current build number extracted from app metadata (e.g. '4' from 1.0.0+4)
  String get currentBuildNumber => _packageInfo?.buildNumber ?? '4';

  /// Current version name (e.g. '1.0.0')
  String get currentVersionName => _packageInfo?.version ?? '1.0.0';

  /// Whether the app is currently force-locked
  bool get isLocked => updateConfigNotifier.value != null;

  /// Initialize package info to extract the running app's build number and version
  Future<void> init() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      debugPrint('[AppVersionService] Detected local build: $currentBuildNumber (v$currentVersionName)');
    } catch (e) {
      debugPrint('[AppVersionService] Failed to read package info (using fallback): $e');
    }
  }

  /// Starts listening to the remote version configuration in Firebase Realtime Database.
  void startVersionListener({
    String rootNode = '0',
    String? databaseUrl,
    String? moduleKey,
  }) {
    _versionSubscription?.cancel();

    final String dbUrl = databaseUrl ?? defaultDatabaseUrl;
    final FirebaseDatabase db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dbUrl,
    );

    final DatabaseReference ref = db.ref(rootNode);
    debugPrint('[AppVersionService] Connecting to Realtime Database at $dbUrl, path: $rootNode');

    _versionSubscription = ref.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        debugPrint('[AppVersionService] Received Realtime Database snapshot: $data');

        if (data == null || data is! Map) {
          debugPrint('[AppVersionService] Node "$rootNode" does not exist or is empty.');
          return;
        }

        final config = Map<String, dynamic>.from(data);

        // Determine platform-specific keys
        final bool isIosPlatform = !kIsWeb && Platform.isIOS;
        final String versionKey = moduleKey ?? (isIosPlatform ? 'ALLOWED_VERSIONS_IOS' : 'ALLOWED_VERSIONS');
        final String addressKey = isIosPlatform ? 'ADDRESS_iOS' : 'ADDRESS';

        final dynamic rawAllowed = config[versionKey] ?? config['ALLOWED_VERSIONS'];
        final String allowedStr = rawAllowed?.toString() ?? '';

        final String text = config['TEXT']?.toString() ??
            'A new version of My KGRA is available. Please update to continue.';
        final String buttonText = config['BUTTON']?.toString() ?? 'UPDATE NOW';
        final String address = config[addressKey]?.toString() ?? config['ADDRESS']?.toString() ?? '';

        _evaluateVersion(
          allowedVersionsStr: allowedStr,
          text: text,
          buttonText: buttonText,
          address: address,
        );
      },
      onError: (error) {
        debugPrint('[AppVersionService] Realtime Database error: $error');
      },
    );
  }

  /// Evaluates whether the installed build number is allowed.
  void _evaluateVersion({
    required String allowedVersionsStr,
    required String text,
    required String buttonText,
    required String address,
  }) {
    // Split comma-separated allowed build numbers/versions
    final List<String> allowedList = allowedVersionsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final String localBuild = currentBuildNumber;

    // The app is allowed ONLY if allowedList is not empty AND contains localBuild
    final bool isAllowed = allowedList.isNotEmpty && allowedList.contains(localBuild);

    debugPrint(
      '[AppVersionService] Checking build: "$localBuild" vs allowed: $allowedList -> ${isAllowed ? "PASS (Unlocked)" : "LOCK (Force Update)"}',
    );

    if (!isAllowed) {
      updateConfigNotifier.value = ForceUpdateConfig(
        message: text,
        buttonText: buttonText,
        storeUrl: address,
      );
    } else {
      updateConfigNotifier.value = null;
    }
  }

  /// Disposes the listener
  void dispose() {
    _versionSubscription?.cancel();
  }
}
