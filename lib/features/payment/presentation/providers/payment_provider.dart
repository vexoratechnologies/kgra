import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../data/models/payment_config_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;
  Razorpay? _razorpay;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _currentOrderId;
  double _currentAmount = 0.0;
  String _currentPurpose = 'ANNUAL_MEMBERSHIP_FEE';
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPhone;
  String? _currentUserEmail;
  String? _currentMembershipId;
  String? _currentDesignation;
  String? _currentInstitution;
  String? _currentZone;

  PaymentConfigModel _config = const PaymentConfigModel();
  String _appVersion = '1.0.0';
  String? _buildNumber;
  bool _isConfigLoaded = false;
  final Completer<void> _configCompleter = Completer<void>();
  StreamSubscription<PaymentConfigModel>? _configSubscription;

  // Callbacks for UI notifications
  VoidCallback? onPaymentSuccess;
  Function(String error)? onPaymentError;

  PaymentProvider({PaymentRepository? repository})
      : _repository = repository ?? PaymentRepository() {
    _init();
  }

  bool get isLoading => _isLoading;
  bool get isConfigLoaded => _isConfigLoaded;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  PaymentConfigModel get config => _config;
  String get appVersion => _appVersion;
  String? get buildNumber => _buildNumber;

  /// Awaits the initial remote config from Realtime Database (used by Splash Screen)
  Future<void> waitForConfig({Duration timeout = const Duration(seconds: 2)}) async {
    if (_isConfigLoaded) return;
    try {
      await _configCompleter.future.timeout(timeout);
    } catch (_) {}
  }

  /// Check whether payment feature is visible on current device & app version
  bool get isPaymentAllowed {
    if (!_isConfigLoaded) return false;
    final bool isIos = !kIsWeb && Platform.isIOS;
    return _config.isPaymentAllowedFor(
      isIos: isIos,
      appVersion: _appVersion,
      buildNumber: _buildNumber,
    );
  }

  Future<void> _init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
      debugPrint('[PaymentProvider] Local app info: version=$_appVersion, buildNumber=$_buildNumber');
    } catch (e) {
      debugPrint('[PaymentProvider] PackageInfo error: $e');
    }

    // Subscribe to remote version & platform on/off config from Realtime Database
    _configSubscription = _repository.watchPaymentConfig().listen((newConfig) {
      _config = newConfig;
      _isConfigLoaded = true;
      if (!_configCompleter.isCompleted) {
        _configCompleter.complete();
      }
      final bool isIos = !kIsWeb && Platform.isIOS;
      debugPrint('[PaymentProvider] RTDB update: platform=${isIos ? "iOS" : "Android"}, isPaymentAllowed=$isPaymentAllowed, disabledAndroid=${newConfig.disabledAndroidVersions}, disabledIos=${newConfig.disabledIosVersions}, amount=${newConfig.annualMembershipAmount}, keyId=${newConfig.razorpayKeyId}');
      notifyListeners();
    });

    _repository.firebaseService.initializeDefaultConfigIfNeeded();

    _initRazorpay();
  }

  void _initRazorpay() {
    if (kIsWeb) return;
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    } catch (e) {
      debugPrint('[PaymentProvider] Razorpay init notice: $e');
    }
  }

  /// Launch Razorpay payment flow with comprehensive member metadata
  Future<void> startPayment({
    required double amount,
    required String userId,
    required String userName,
    required String userPhone,
    required String userEmail,
    String? membershipId,
    String? designation,
    String? institution,
    String? zone,
    String purpose = 'ANNUAL_MEMBERSHIP_FEE',
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _currentAmount = amount;
    _currentPurpose = purpose;
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserPhone = userPhone;
    _currentUserEmail = userEmail;
    _currentMembershipId = membershipId;
    _currentDesignation = designation;
    _currentInstitution = institution;
    _currentZone = zone;
    onPaymentSuccess = onSuccess;
    onPaymentError = onError;
    notifyListeners();

    try {
      final platformStr = kIsWeb ? 'WEB' : (Platform.isIOS ? 'IOS' : 'ANDROID');

      // 1. Create order on backend (which also logs to PAYMENT_ATTEMPTS in CAPITAL CASE)
      final orderData = await _repository.createRazorpayOrder(
        amount: amount,
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        userEmail: userEmail,
        membershipId: membershipId,
        designation: designation,
        institution: institution,
        zone: zone,
        purpose: purpose,
        platform: platformStr,
      );

      final bool isFallback = orderData['isClientFallback'] == true;
      final String? orderId = isFallback ? null : (orderData['orderId'] as String?);
      final int amountInPaise = orderData['amountInPaise'] as int? ?? (amount * 100).toInt();
      final String keyId = orderData['keyId'] as String? ?? _config.razorpayKeyId;

      _currentOrderId = orderData['orderId'] as String?;

      // 2. Open Razorpay Checkout modal
      final options = <String, dynamic>{
        'key': keyId,
        'amount': amountInPaise,
        'name': 'KGRA',
        'description': 'KGRA ${_config.membershipTitle}',
        if (orderId != null) 'order_id': orderId,
        'prefill': {
          'contact': userPhone,
          'email': userEmail,
          'name': userName,
        },
        'theme': {
          'color': '#7F0010',
        },
        'modal': {
          'confirm_close': true,
        },
      };

      if (_razorpay != null) {
        _razorpay!.open(options);
      } else {
        throw Exception('Razorpay SDK is not available on this platform.');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (onPaymentError != null) onPaymentError!(_errorMessage!);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('[PaymentProvider] Payment success: ${response.paymentId}');
    _isLoading = true;
    notifyListeners();

    try {
      final platformStr = kIsWeb ? 'WEB' : (Platform.isIOS ? 'IOS' : 'ANDROID');

      final success = await _repository.verifyAndRecordPayment(
        razorpayOrderId: response.orderId ?? _currentOrderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        userId: _currentUserId ?? '',
        userName: _currentUserName,
        userPhone: _currentUserPhone,
        userEmail: _currentUserEmail,
        membershipId: _currentMembershipId,
        designation: _currentDesignation,
        institution: _currentInstitution,
        zone: _currentZone,
        amount: _currentAmount,
        purpose: _currentPurpose,
        platform: platformStr,
      );

      _isLoading = false;
      if (success) {
        _successMessage = 'Payment successful! ID: ${response.paymentId}';
        notifyListeners();
        if (onPaymentSuccess != null) onPaymentSuccess!();
      } else {
        _errorMessage = 'Payment signature verification failed.';
        notifyListeners();
        if (onPaymentError != null) onPaymentError!(_errorMessage!);
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error recording payment: $e';
      notifyListeners();
      if (onPaymentError != null) onPaymentError!(_errorMessage!);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[PaymentProvider] Payment error: ${response.code} - ${response.message}');
    _isLoading = false;
    _errorMessage = response.message ?? 'Payment cancelled or failed.';
    notifyListeners();

    if (_currentOrderId != null) {
      _repository.recordAttemptFailure(
        orderId: _currentOrderId!,
        reason: response.message ?? 'User cancelled or gateway error',
      );
    }

    if (onPaymentError != null) {
      onPaymentError!(_errorMessage!);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[PaymentProvider] External wallet selected: ${response.walletName}');
  }

  /// Watch user's verified payments
  Stream<List<PaymentTransactionModel>> watchUserPayments(String userId) {
    return _repository.watchUserPayments(userId);
  }

  /// Watch user's payment attempts
  Stream<List<PaymentAttemptModel>> watchUserAttempts(String userId) {
    return _repository.watchUserAttempts(userId);
  }

  /// Toggle config remotely (Admin)
  Future<void> updateConfig(PaymentConfigModel newConfig) async {
    await _repository.updatePaymentConfig(newConfig);
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _razorpay?.clear();
    super.dispose();
  }
}
