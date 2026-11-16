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

  /// Current build number extracted from app metadata (e.g. '17' from 1.0.9+17)
  String get currentBuildNumber {
    if (_packageInfo == null) {
      init();
    }
    return _packageInfo?.buildNumber ?? '17';
  }

  /// Current version name (e.g. '1.0.9')
  String get currentVersionName {
    if (_packageInfo == null) {
      init();
    }
    return _packageInfo?.version ?? '1.0.9';
  }

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
    if (kIsWeb) {
      debugPrint('[AppVersionService] Force update listener skipped on web.');
      updateConfigNotifier.value = null;
      return;
    }

    _versionSubscription?.cancel();

    final String dbUrl = databaseUrl ?? defaultDatabaseUrl;
    final FirebaseDatabase db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dbUrl,
    );

    // Listen to root so it works whether fields are placed directly at root '/' or inside node '0'
    final DatabaseReference ref = db.ref();
    debugPrint('[AppVersionService] Connecting to Realtime Database at $dbUrl (auto-supporting root & node "0")');

    _versionSubscription = ref.onValue.listen(
      (DatabaseEvent event) async {
        if (_packageInfo == null) {
          await init();
        }
        final rawData = event.snapshot.value;
        debugPrint('[AppVersionService] Received Realtime Database snapshot: $rawData');

        if (rawData == null || rawData is! Map) {
          debugPrint('[AppVersionService] Realtime Database snapshot is empty or null.');
          return;
        }

        final rootMap = Map<String, dynamic>.from(rawData);
        final Map<String, dynamic> config;
        if (rootMap['0'] is Map) {
          config = Map<String, dynamic>.from(rootMap['0'] as Map);
        } else {
          config = rootMap;
        }

        // Determine platform-specific keys
        final bool isIosPlatform = !kIsWeb && Platform.isIOS;
        final String versionKey = moduleKey ?? (isIosPlatform ? 'ALLOWED_VERSIONS_IOS' : 'ALLOWED_VERSIONS');
        final String addressKey = isIosPlatform ? 'ADDRESS_iOS' : 'ADDRESS';

        final dynamic rawAllowed = config[versionKey] ??
            (isIosPlatform
                ? (config['ALLOWED_VERSIONS_IOS'] ?? config['ALLOWED_VERSIONS_ios'] ?? config['ALLOWED_VERSIONS_Ios'])
                : null) ??
            config['ALLOWED_VERSIONS'];
        final String allowedStr = rawAllowed?.toString() ?? '';

        final String text = config['TEXT']?.toString() ??
            'A new version of My KGRA is available. Please update to continue.';
        final String buttonText = config['BUTTON']?.toString() ?? 'UPDATE NOW';

        final dynamic rawAddress = isIosPlatform
            ? (config['ADDRESS_iOS'] ??
                config['ADDRESS_IOS'] ??
                config['ADDRESS_ios'] ??
                config['ADDRESS_Ios'] ??
                config['ADDRESS'])
            : (config[addressKey] ?? config['ADDRESS']);
        final String address = rawAddress?.toString() ?? '';

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
    if (kIsWeb) {
      updateConfigNotifier.value = null;
      return;
    }
    // Split comma-separated allowed build numbers/versions
    final List<String> allowedList = allowedVersionsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final String localBuild = currentBuildNumber;
    final String localVersion = currentVersionName;
    final String fullVersion = '$localVersion+$localBuild';

    // The app is allowed ONLY if allowedList is not empty AND contains localBuild, localVersion, or fullVersion
    final bool isAllowed = allowedList.isNotEmpty &&
        (allowedList.contains(localBuild) ||
         allowedList.contains(localVersion) ||
         allowedList.contains(fullVersion));

    debugPrint(
      '[AppVersionService] Checking build: "$localBuild" (v$localVersion) vs allowed: $allowedList -> ${isAllowed ? "PASS (Unlocked)" : "LOCK (Force Update)"}',
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
