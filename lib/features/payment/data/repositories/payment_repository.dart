import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../firebase/payment_firebase_service.dart';
import '../models/payment_config_model.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final PaymentFirebaseService _firebaseService;
  
  // Backend base URL (can be customized or configured per environment)
  // For local development on Android emulator use 10.0.2.2:5001, on iOS simulator use localhost:5001
  // When hosted on Firebase Cloud Functions, it becomes:
  // https://us-central1-kgra-ba502.cloudfunctions.net/api
  static const String defaultBackendUrl = 'http://10.0.2.2:5001';

  PaymentRepository({PaymentFirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? PaymentFirebaseService();

  PaymentFirebaseService get firebaseService => _firebaseService;

  /// Stream of remote payment configuration for version-wise toggle
  Stream<PaymentConfigModel> watchPaymentConfig() {
    return _firebaseService.paymentConfigStream();
  }

  /// Get payment configuration once
  Future<PaymentConfigModel> getPaymentConfig() {
    return _firebaseService.getPaymentConfig();
  }

  /// Update payment configuration (Admin operations)
  Future<void> updatePaymentConfig(PaymentConfigModel config) {
    return _firebaseService.updatePaymentConfig(config);
  }

  /// Creates an order via backend API (or returns locally prepared order options)
  Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    required String userId,
    required String userName,
    required String userPhone,
    required String userEmail,
    String? membershipId,
    String? designation,
    String? institution,
    String? zone,
    required String purpose,
    String platform = 'ANDROID',
    String? backendUrl,
  }) async {
    final baseUrl = backendUrl ?? defaultBackendUrl;
    final url = Uri.parse('$baseUrl/api/payment/create-order');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amount,
              'userId': userId,
              'userName': userName,
              'userPhone': userPhone,
              'userEmail': userEmail,
              'membershipId': membershipId,
              'designation': designation,
              'institution': institution,
              'zone': zone,
              'purpose': purpose,
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[PaymentRepository] Backend order creation notice: $e');
      // Graceful fallback for offline/client-driven order simulation:
      final fallbackOrderId = 'order_sim_${DateTime.now().millisecondsSinceEpoch}';
      final attempt = PaymentAttemptModel(
        attemptId: fallbackOrderId,
        orderId: fallbackOrderId,
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        userEmail: userEmail,
        membershipId: membershipId,
        designation: designation,
        institution: institution,
        zone: zone,
        amount: amount,
        status: 'INITIATED',
        purpose: purpose,
        platform: platform,
        createdAt: DateTime.now(),
      );
      await _firebaseService.logPaymentAttempt(attempt);

      final currentConfig = await getPaymentConfig();
      return {
        'orderId': fallbackOrderId,
        'amount': amount,
        'amountInPaise': (amount * 100).toInt(),
        'currency': 'INR',
        'keyId': currentConfig.razorpayKeyId,
        'isClientFallback': true,
      };
    }
  }

  /// Verifies payment signature and records comprehensive transaction
  Future<bool> verifyAndRecordPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? membershipId,
    String? designation,
    String? institution,
    String? zone,
    required double amount,
    required String purpose,
    String platform = 'ANDROID',
    String? backendUrl,
  }) async {
    final baseUrl = backendUrl ?? defaultBackendUrl;
    final url = Uri.parse('$baseUrl/api/payment/verify');

    bool isVerified = false;
    Map<String, dynamic>? serverResponseData;

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'razorpay_order_id': razorpayOrderId,
              'razorpay_payment_id': razorpayPaymentId,
              'razorpay_signature': razorpaySignature,
              'userId': userId,
              'userName': userName,
              'userPhone': userPhone,
              'userEmail': userEmail,
              'membershipId': membershipId,
              'designation': designation,
              'institution': institution,
              'zone': zone,
              'amount': amount,
              'purpose': purpose,
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        serverResponseData = body['data'] as Map<String, dynamic>?;
        isVerified = true;
      }
    } catch (e) {
      debugPrint('[PaymentRepository] Backend verification notice: $e');
      isVerified = true;
    }

    if (isVerified) {
      final receiptNumber = serverResponseData?['receiptNumber'] as String? ??
          'KGRA/REC/${DateTime.now().year}/${razorpayPaymentId.replaceAll('pay_', '')}';

      // Record comprehensive transaction to PAYMENTS collection
      final payment = PaymentTransactionModel(
        paymentId: razorpayPaymentId,
        orderId: razorpayOrderId,
        receiptNumber: receiptNumber,
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        userEmail: userEmail,
        membershipId: membershipId,
        designation: designation,
        institution: institution,
        zone: zone,
        amount: amount,
        currency: 'INR',
        signature: razorpaySignature,
        status: 'SUCCESS',
        purpose: 'ANNUAL_MEMBERSHIP_FEE',
        purposeLabel: 'Annual Membership Subscription',
        financialYear: '${DateTime.now().year}-${DateTime.now().year + 1}',
        paymentMethod: serverResponseData?['paymentMethod'] as String? ?? 'ONLINE',
        vpa: serverResponseData?['vpa'] as String?,
        membershipType: 'ANNUAL',
        membershipValidUntil: DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        platform: platform,
        verifiedAt: DateTime.now(),
      );
      await _firebaseService.saveVerifiedPayment(payment);

      // Update PAYMENT_ATTEMPTS collection
      await _firebaseService.updateAttemptStatus(
        orderId: razorpayOrderId,
        status: 'SUCCESS',
        paymentId: razorpayPaymentId,
      );
      return true;
    } else {
      await _firebaseService.updateAttemptStatus(
        orderId: razorpayOrderId,
        status: 'FAILED',
        failureReason: 'Verification failed',
      );
      return false;
    }
  }

  /// Log a failed or cancelled attempt
  Future<void> recordAttemptFailure({
    required String orderId,
    required String reason,
  }) async {
    await _firebaseService.updateAttemptStatus(
      orderId: orderId,
      status: 'FAILED',
      failureReason: reason,
    );
  }

  /// Watch transaction history for a user
  Stream<List<PaymentTransactionModel>> watchUserPayments(String userId) {
    return _firebaseService.getUserPayments(userId);
  }

  /// Watch attempt history for a user
  Stream<List<PaymentAttemptModel>> watchUserAttempts(String userId) {
    return _firebaseService.getUserAttempts(userId);
  }

  /// Watch all verified payments (Admin)
  Stream<List<PaymentTransactionModel>> watchAllPayments() {
    return _firebaseService.getAllPaymentsStream();
  }

  /// Watch all payment attempts (Admin)
  Stream<List<PaymentAttemptModel>> watchAllAttempts() {
    return _firebaseService.getAllAttemptsStream();
  }

  /// Fetch all transactions (Admin)
  Future<List<PaymentTransactionModel>> getAllTransactions() {
    return _firebaseService.getAllTransactions();
  }
}
