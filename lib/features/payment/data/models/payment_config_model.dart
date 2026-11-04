/// Configuration model for remote version-wise and platform-wise payment visibility.
class PaymentConfigModel {
  final bool isPaymentGloballyEnabled;
  final bool isIosPaymentEnabled;
  final bool isAndroidPaymentEnabled;
  final List<String> disabledIosVersions;
  final List<String> disabledAndroidVersions;
  final String razorpayKeyId;
  final String razorpayKeySecret;
  final String infoMessageIos;
  final double annualMembershipAmount;
  final String membershipTitle;
  final String membershipDescription;
  final String membershipPurpose;

  const PaymentConfigModel({
    this.isPaymentGloballyEnabled = true,
    this.isIosPaymentEnabled = true,
    this.isAndroidPaymentEnabled = true,
    this.disabledIosVersions = const ['1.0.5', '1.0.0'],
    this.disabledAndroidVersions = const [],
    this.razorpayKeyId = 'rzp_test_TfREKwuczLH0HV',
    this.razorpayKeySecret = '6PRLktauO7P5CC0eO9q7EYlH',
    this.infoMessageIos = 'To renew or process association membership dues on iOS, please visit the official KGRA web portal or contact your district committee.',
    this.annualMembershipAmount = 1000.0,
    this.membershipTitle = 'Annual Membership',
    this.membershipDescription = 'Standard annual association subscription for 12 months.',
    this.membershipPurpose = 'ANNUAL_MEMBERSHIP_FEE',
  });

  static List<String> _parseVersions(dynamic raw, List<String> fallback) {
    if (raw == null) return fallback;
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [raw.toString().trim()];
  }

  static bool _matchesVersion({
    required List<String> disabledList,
    required String appVersion,
    String? buildNumber,
  }) {
    final String fullVersion = (buildNumber != null && buildNumber.isNotEmpty)
        ? '$appVersion+$buildNumber'
        : appVersion;

    for (final rawItem in disabledList) {
      final item = rawItem.trim();
      if (item.isEmpty) continue;

      // 1. Exact match with full version string (e.g. "1.0.5+12")
      if (item == fullVersion) return true;

      // 2. Exact match with version name (e.g. "1.0.5")
      if (item == appVersion) return true;

      // 3. Exact match with build number (e.g. "12")
      if (buildNumber != null && item == buildNumber) return true;

      // 4. If item in RTDB has "+", e.g. "1.0.5+12", check components
      if (item.contains('+')) {
        final parts = item.split('+');
        final itemVer = parts[0].trim();
        final itemBuild = parts.length > 1 ? parts[1].trim() : '';

        final bool verMatches = itemVer == appVersion;
        final bool buildMatches = buildNumber == null ||
            buildNumber.isEmpty ||
            itemBuild.isEmpty ||
            itemBuild == buildNumber;

        if (verMatches && buildMatches) return true;
      }
    }
    return false;
  }

  static double _parseDouble(dynamic raw, double fallback) {
    if (raw == null) return fallback;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static bool? _parseBool(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is String) {
      final lower = raw.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (raw is num) return raw != 0;
    return null;
  }

  factory PaymentConfigModel.fromMap(dynamic rawData) {
    if (rawData == null || rawData is! Map) return const PaymentConfigModel();

    final data = Map<dynamic, dynamic>.from(rawData);

    // Support root fields, nested node '0' fields, or nested 'payment_config' node
    final Map<dynamic, dynamic> source =
        (data['0'] is Map) ? Map<dynamic, dynamic>.from(data['0']) : data;
    final Map<dynamic, dynamic> target =
        (source['payment_config'] is Map)
            ? Map<dynamic, dynamic>.from(source['payment_config'])
            : (data['payment_config'] is Map)
                ? Map<dynamic, dynamic>.from(data['payment_config'])
                : source;

    final rawDisabledIos = target['DISABLED_IOS_VERSIONS'] ??
        target['disabled_ios_versions'] ??
        target['disabledIosVersions'] ??
        target['DISABLED_VERSIONS_IOS'] ??
        source['DISABLED_IOS_VERSIONS'] ??
        source['disabled_ios_versions'] ??
        source['disabledIosVersions'] ??
        data['DISABLED_IOS_VERSIONS'] ??
        data['disabled_ios_versions'] ??
        data['disabledIosVersions'];

    final rawDisabledAndroid = target['DISABLED_ANDROID_VERSIONS'] ??
        target['disabled_android_versions'] ??
        target['disabledAndroidVersions'] ??
        source['DISABLED_ANDROID_VERSIONS'] ??
        source['disabled_android_versions'] ??
        source['disabledAndroidVersions'] ??
        data['DISABLED_ANDROID_VERSIONS'] ??
        data['disabled_android_versions'] ??
        data['disabledAndroidVersions'];

    final rawIsIosEnabled = target['IS_IOS_PAYMENT_ENABLED'] ??
        target['is_ios_payment_enabled'] ??
        target['isIosPaymentEnabled'] ??
        source['IS_IOS_PAYMENT_ENABLED'] ??
        source['isIosPaymentEnabled'] ??
        data['IS_IOS_PAYMENT_ENABLED'] ??
        data['isIosPaymentEnabled'];

    final rawIsAndroidEnabled = target['IS_ANDROID_PAYMENT_ENABLED'] ??
        target['is_android_payment_enabled'] ??
        target['isAndroidPaymentEnabled'] ??
        source['IS_ANDROID_PAYMENT_ENABLED'] ??
        source['isAndroidPaymentEnabled'] ??
        data['IS_ANDROID_PAYMENT_ENABLED'] ??
        data['isAndroidPaymentEnabled'];

    final rawIsGlobalEnabled = target['IS_PAYMENT_GLOBALLY_ENABLED'] ??
        target['is_payment_globally_enabled'] ??
        target['isPaymentGloballyEnabled'] ??
        source['IS_PAYMENT_GLOBALLY_ENABLED'] ??
        source['isPaymentGloballyEnabled'] ??
        data['IS_PAYMENT_GLOBALLY_ENABLED'] ??
        data['isPaymentGloballyEnabled'];

    final rawRazorpayKey = target['RAZORPAY_KEY_ID'] ??
        target['razorpay_key_id'] ??
        target['razorpayKeyId'] ??
        source['RAZORPAY_KEY_ID'] ??
        source['razorpayKeyId'] ??
        data['RAZORPAY_KEY_ID'] ??
        data['razorpayKeyId'];

    final rawRazorpaySecret = target['RAZORPAY_KEY_SECRET'] ??
        target['razorpay_key_secret'] ??
        target['razorpayKeySecret'] ??
        source['RAZORPAY_KEY_SECRET'] ??
        source['razorpayKeySecret'] ??
        data['RAZORPAY_KEY_SECRET'] ??
        data['razorpayKeySecret'];

    final rawInfoMessageIos = target['INFO_MESSAGE_IOS'] ??
        target['info_message_ios'] ??
        target['infoMessageIos'] ??
        source['INFO_MESSAGE_IOS'] ??
        source['infoMessageIos'] ??
        data['INFO_MESSAGE_IOS'] ??
        data['infoMessageIos'];

    final rawAmount = target['ANNUAL_MEMBERSHIP_AMOUNT'] ??
        target['annual_membership_amount'] ??
        target['annualMembershipAmount'] ??
        target['MEMBERSHIP_AMOUNT'] ??
        target['membership_amount'] ??
        target['membershipAmount'] ??
        target['MEMBERSHIP_FEE'] ??
        target['membership_fee'] ??
        target['membershipFee'] ??
        target['AMOUNT'] ??
        target['amount'] ??
        target['ANNUAL_MEMBERSHIP_FEE'] ??
        target['annual_membership_fee'] ??
        source['ANNUAL_MEMBERSHIP_AMOUNT'] ??
        source['annual_membership_amount'] ??
        source['MEMBERSHIP_AMOUNT'] ??
        source['MEMBERSHIP_FEE'] ??
        source['AMOUNT'] ??
        source['amount'] ??
        data['ANNUAL_MEMBERSHIP_AMOUNT'] ??
        data['annual_membership_amount'] ??
        data['MEMBERSHIP_AMOUNT'] ??
        data['MEMBERSHIP_FEE'] ??
        data['AMOUNT'] ??
        data['amount'];

    final rawTitle = target['MEMBERSHIP_TITLE'] ??
        target['membership_title'] ??
        target['membershipTitle'] ??
        target['TITLE'] ??
        target['title'] ??
        source['MEMBERSHIP_TITLE'] ??
        source['title'] ??
        data['MEMBERSHIP_TITLE'] ??
        data['title'];

    final rawDescription = target['MEMBERSHIP_DESCRIPTION'] ??
        target['membership_description'] ??
        target['membershipDescription'] ??
        target['DESCRIPTION'] ??
        target['description'] ??
        source['MEMBERSHIP_DESCRIPTION'] ??
        source['description'] ??
        data['MEMBERSHIP_DESCRIPTION'] ??
        data['description'];

    final rawPurpose = target['MEMBERSHIP_PURPOSE'] ??
        target['membership_purpose'] ??
        target['membershipPurpose'] ??
        target['PURPOSE'] ??
        target['purpose'] ??
        source['MEMBERSHIP_PURPOSE'] ??
        source['purpose'] ??
        data['MEMBERSHIP_PURPOSE'] ??
        data['purpose'];

    return PaymentConfigModel(
      isPaymentGloballyEnabled: _parseBool(rawIsGlobalEnabled) ?? true,
      isIosPaymentEnabled: _parseBool(rawIsIosEnabled) ?? true,
      isAndroidPaymentEnabled: _parseBool(rawIsAndroidEnabled) ?? true,
      disabledIosVersions: _parseVersions(rawDisabledIos, const ['1.0.5', '1.0.0']),
      disabledAndroidVersions: _parseVersions(rawDisabledAndroid, const []),
      razorpayKeyId: rawRazorpayKey?.toString() ?? 'rzp_test_TfREKwuczLH0HV',
      razorpayKeySecret: rawRazorpaySecret?.toString() ?? '6PRLktauO7P5CC0eO9q7EYlH',
      infoMessageIos: rawInfoMessageIos?.toString() ??
          'To renew or process association membership dues on iOS, please visit the official KGRA web portal or contact your district committee.',
      annualMembershipAmount: _parseDouble(rawAmount, 1000.0),
      membershipTitle: rawTitle?.toString() ?? 'Annual Membership',
      membershipDescription: rawDescription?.toString() ??
          'Standard annual association subscription for 12 months.',
      membershipPurpose: rawPurpose?.toString() ?? 'ANNUAL_MEMBERSHIP_FEE',
    );
  }

  PaymentConfigModel copyWith({
    bool? isPaymentGloballyEnabled,
    bool? isIosPaymentEnabled,
    bool? isAndroidPaymentEnabled,
    List<String>? disabledIosVersions,
    List<String>? disabledAndroidVersions,
    String? razorpayKeyId,
    String? razorpayKeySecret,
    String? infoMessageIos,
    double? annualMembershipAmount,
    String? membershipTitle,
    String? membershipDescription,
    String? membershipPurpose,
  }) {
    return PaymentConfigModel(
      isPaymentGloballyEnabled: isPaymentGloballyEnabled ?? this.isPaymentGloballyEnabled,
      isIosPaymentEnabled: isIosPaymentEnabled ?? this.isIosPaymentEnabled,
      isAndroidPaymentEnabled: isAndroidPaymentEnabled ?? this.isAndroidPaymentEnabled,
      disabledIosVersions: disabledIosVersions ?? this.disabledIosVersions,
      disabledAndroidVersions: disabledAndroidVersions ?? this.disabledAndroidVersions,
      razorpayKeyId: razorpayKeyId ?? this.razorpayKeyId,
      razorpayKeySecret: razorpayKeySecret ?? this.razorpayKeySecret,
      infoMessageIos: infoMessageIos ?? this.infoMessageIos,
      annualMembershipAmount: annualMembershipAmount ?? this.annualMembershipAmount,
      membershipTitle: membershipTitle ?? this.membershipTitle,
      membershipDescription: membershipDescription ?? this.membershipDescription,
      membershipPurpose: membershipPurpose ?? this.membershipPurpose,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPaymentGloballyEnabled': isPaymentGloballyEnabled,
      'isIosPaymentEnabled': isIosPaymentEnabled,
      'isAndroidPaymentEnabled': isAndroidPaymentEnabled,
      'disabledIosVersions': disabledIosVersions,
      'disabledAndroidVersions': disabledAndroidVersions,
      'razorpayKeyId': razorpayKeyId,
      'razorpayKeySecret': razorpayKeySecret,
      'infoMessageIos': infoMessageIos,
      'annualMembershipAmount': annualMembershipAmount,
      'membershipTitle': membershipTitle,
      'membershipDescription': membershipDescription,
      'membershipPurpose': membershipPurpose,
    };
  }

  /// Determines whether payment is visible/enabled for the given platform, app version, and build number
  bool isPaymentAllowedFor({
    required bool isIos,
    required String appVersion,
    String? buildNumber,
  }) {
    if (!isPaymentGloballyEnabled) return false;

    if (isIos) {
      if (!isIosPaymentEnabled) return false;
      if (_matchesVersion(
        disabledList: disabledIosVersions,
        appVersion: appVersion,
        buildNumber: buildNumber,
      )) {
        return false;
      }
      return true;
    } else {
      if (!isAndroidPaymentEnabled) return false;
      if (_matchesVersion(
        disabledList: disabledAndroidVersions,
        appVersion: appVersion,
        buildNumber: buildNumber,
      )) {
        return false;
      }
      return true;
    }
  }
}
