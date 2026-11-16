import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_config_model.dart';
import '../models/payment_model.dart';

/// Service that interacts directly with Cloud Firestore for payments and attempts,
/// and Firebase Realtime Database for real-time version/payment switches.
/// All collections use CAPITAL CASE naming as per architecture requirements.
class PaymentFirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _realtimeDb;

  // Realtime Database root node used for app version & remote config (same node '0' used by AppVersionService)
  static const String rtdbRootNode = '0';
  static const String defaultDatabaseUrl = 'https://kgra-ba502-default-rtdb.firebaseio.com';

  // Collection names in CAPITAL CASE
  static const String attemptsCollection = 'PAYMENT_ATTEMPTS';
  static const String paymentsCollection = 'PAYMENTS';
  static const String configCollection = 'CONFIG';
  static const String configDocId = 'PAYMENT_CONFIG';
  static const String usersCollection = 'USERS';

  PaymentFirebaseService({
    FirebaseFirestore? firestore,
    FirebaseDatabase? realtimeDb,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _realtimeDb = realtimeDb ?? _initRealtimeDb();

  static FirebaseDatabase _initRealtimeDb() {
    try {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: defaultDatabaseUrl,
      );
    } catch (_) {
      return FirebaseDatabase.instance;
    }
  }

  /// Stream to listen to real-time payment configuration & version switches from Firebase Realtime Database.
  /// Listens to root node '0' (so DISABLED_IOS_VERSIONS changes update immediately in real-time).
  Stream<PaymentConfigModel> paymentConfigStream() {
    return _realtimeDb
        .ref(rtdbRootNode)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        return PaymentConfigModel.fromMap(data);
      }
      return const PaymentConfigModel();
    });
  }

  /// Fetch payment configuration once from Realtime Database
  Future<PaymentConfigModel> getPaymentConfig() async {
    try {
      final snapshot = await _realtimeDb.ref(rtdbRootNode).get();
      if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
        return PaymentConfigModel.fromMap(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint('[PaymentFirebaseService] Error getting RTDB config: $e');
    }
    return const PaymentConfigModel();
  }

  /// Update remote payment configuration in Realtime Database node '0' (and sync to Firestore)
  /// Note: ANNUAL_MEMBERSHIP_AMOUNT is strictly fetch-only and is NEVER updated or overwritten here.
  Future<void> updatePaymentConfig(PaymentConfigModel config) async {
    try {
      await _realtimeDb.ref(rtdbRootNode).update({
        'DISABLED_IOS_VERSIONS': config.disabledIosVersions.join(', '),
        'DISABLED_ANDROID_VERSIONS': config.disabledAndroidVersions.join(', '),
        'IS_IOS_PAYMENT_ENABLED': config.isIosPaymentEnabled,
        'IS_ANDROID_PAYMENT_ENABLED': config.isAndroidPaymentEnabled,
        'IS_PAYMENT_GLOBALLY_ENABLED': config.isPaymentGloballyEnabled,
        'RAZORPAY_KEY_ID': config.razorpayKeyId,
        'RAZORPAY_KEY_SECRET': config.razorpayKeySecret,
        'MEMBERSHIP_TITLE': config.membershipTitle,
        'MEMBERSHIP_DESCRIPTION': config.membershipDescription,
        'MEMBERSHIP_PURPOSE': config.membershipPurpose,
      });

      final firestoreData = config.toMap();
      firestoreData.remove('annualMembershipAmount');

      await _firestore
          .collection(configCollection)
          .doc(configDocId)
          .set(firestoreData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[PaymentFirebaseService] Error updating config: $e');
    }
  }

  /// Ensure initial RTDB keys exist in node '0'
  /// Note: ANNUAL_MEMBERSHIP_AMOUNT is fetch-only and is NEVER written or overwritten.
  Future<void> initializeDefaultConfigIfNeeded() async {
    try {
      final snapshot = await _realtimeDb.ref(rtdbRootNode).get();
      final updates = <String, dynamic>{};
      if (!snapshot.exists || snapshot.value == null || snapshot.value is! Map) {
        updates['RAZORPAY_KEY_ID'] = 'rzp_test_TfREKwuczLH0HV';
        updates['RAZORPAY_KEY_SECRET'] = '6PRLktauO7P5CC0eO9q7EYlH';
        updates['MEMBERSHIP_TITLE'] = 'Annual Membership';
        updates['MEMBERSHIP_DESCRIPTION'] = 'Standard annual association subscription for 12 months.';
        updates['MEMBERSHIP_PURPOSE'] = 'ANNUAL_MEMBERSHIP_FEE';
      } else {
        final data = snapshot.value as Map;
        if (data['RAZORPAY_KEY_ID'] == null && data['razorpay_key_id'] == null) {
          updates['RAZORPAY_KEY_ID'] = 'rzp_test_TfREKwuczLH0HV';
        }
        if (data['RAZORPAY_KEY_SECRET'] == null && data['razorpay_key_secret'] == null) {
          updates['RAZORPAY_KEY_SECRET'] = '6PRLktauO7P5CC0eO9q7EYlH';
        }
        if (data['MEMBERSHIP_TITLE'] == null && data['membership_title'] == null) {
          updates['MEMBERSHIP_TITLE'] = 'Annual Membership';
        }
        if (data['MEMBERSHIP_DESCRIPTION'] == null && data['membership_description'] == null) {
          updates['MEMBERSHIP_DESCRIPTION'] = 'Standard annual association subscription for 12 months.';
        }
        if (data['MEMBERSHIP_PURPOSE'] == null && data['membership_purpose'] == null) {
          updates['MEMBERSHIP_PURPOSE'] = 'ANNUAL_MEMBERSHIP_FEE';
        }
      }
      if (updates.isNotEmpty) {
        await _realtimeDb.ref(rtdbRootNode).update(updates);
        debugPrint('[PaymentFirebaseService] Synced missing payment keys to RTDB node 0: ${updates.keys}');
      }
    } catch (e) {
      debugPrint('[PaymentFirebaseService] RTDB default config initialization notice: $e');
    }
  }

  /// Record or update a payment attempt in PAYMENT_ATTEMPTS
  Future<void> logPaymentAttempt(PaymentAttemptModel attempt) async {
    try {
      await _firestore
          .collection(attemptsCollection)
          .doc(attempt.orderId)
          .set(attempt.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[PaymentFirebaseService] Error logging payment attempt: $e');
      rethrow;
    }
  }

  /// Update payment attempt status (e.g. SUCCESS, FAILED, CANCELLED)
  Future<void> updateAttemptStatus({
    required String orderId,
    required String status,
    String? paymentId,
    String? failureReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (paymentId != null) updates['paymentId'] = paymentId;
      if (failureReason != null) updates['failureReason'] = failureReason;

      await _firestore
          .collection(attemptsCollection)
          .doc(orderId)
          .set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[PaymentFirebaseService] Error updating attempt status: $e');
    }
  }

  /// Save verified payment to PAYMENTS collection
  Future<void> saveVerifiedPayment(PaymentTransactionModel payment) async {
    try {
      await _firestore
          .collection(paymentsCollection)
          .doc(payment.paymentId)
          .set(payment.toMap(), SetOptions(merge: true));

      // Also update user's membership if userId is provided
      if (payment.userId != null && payment.userId!.isNotEmpty) {
        await _firestore.collection(usersCollection).doc(payment.userId).set({
          'isMemberPaid': true,
          'membershipExpiryDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 365)),
          ),
          'lastPaymentId': payment.paymentId,
          'lastPaymentDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[PaymentFirebaseService] Error saving verified payment: $e');
      rethrow;
    }
  }

  /// Stream user's payments from PAYMENTS collection
  Stream<List<PaymentTransactionModel>> getUserPayments(String userId) {
    return _firestore
        .collection(paymentsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentTransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream user's attempts from PAYMENT_ATTEMPTS collection
  Stream<List<PaymentAttemptModel>> getUserAttempts(String userId) {
    return _firestore
        .collection(attemptsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentAttemptModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream all payments from PAYMENTS collection
  Stream<List<PaymentTransactionModel>> getAllPaymentsStream() {
    return _firestore
        .collection(paymentsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentTransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  /// Stream all attempts from PAYMENT_ATTEMPTS collection
  Stream<List<PaymentAttemptModel>> getAllAttemptsStream() {
    return _firestore
        .collection(attemptsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentAttemptModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  /// Fetch all unified transactions (verified payments and any distinct attempts)
  Future<List<PaymentTransactionModel>> getAllTransactions() async {
    final Map<String, PaymentTransactionModel> transactions = {};

    // 1. Fetch completed payments
    try {
      final paymentsSnapshot = await _firestore.collection(paymentsCollection).get();
      for (final doc in paymentsSnapshot.docs) {
        final payment = PaymentTransactionModel.fromMap(doc.data(), doc.id);
        final key = payment.orderId.isNotEmpty ? payment.orderId : payment.paymentId;
        transactions[key] = payment;
      }
    } catch (e) {
      debugPrint('[PaymentFirebaseService] Error fetching PAYMENTS: $e');
    }

    // 2. Fetch attempts for any initiated/failed/cancelled
    try {
      final attemptsSnapshot = await _firestore.collection(attemptsCollection).get();
      for (final doc in attemptsSnapshot.docs) {
        final attempt = PaymentAttemptModel.fromMap(doc.data(), doc.id);
        final key = attempt.orderId.isNotEmpty ? attempt.orderId : attempt.attemptId;
        if (!transactions.containsKey(key)) {
          transactions[key] = PaymentTransactionModel(
            paymentId: attempt.paymentId ?? attempt.attemptId,
            orderId: attempt.orderId,
            receiptNumber: attempt.receiptNumber ?? attempt.receipt,
            attemptId: attempt.attemptId,
            userId: attempt.userId,
            userName: attempt.userName,
            userPhone: attempt.userPhone,
            userEmail: attempt.userEmail,
            membershipId: attempt.membershipId,
            designation: attempt.designation,
            institution: attempt.institution,
            zone: attempt.zone,
            amount: attempt.amount,
            currency: attempt.currency,
            status: attempt.status,
            purpose: attempt.purpose,
            financialYear: attempt.financialYear,
            paymentMethod: attempt.paymentMethod,
            platform: attempt.platform,
            paidAt: attempt.createdAt,
            verifiedAt: attempt.updatedAt,
          );
        }
      }
    } catch (e) {
      debugPrint('[PaymentFirebaseService] Error fetching PAYMENT_ATTEMPTS: $e');
    }

    final list = transactions.values.toList();
    list.sort((a, b) {
      final aDate = a.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.paidAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return list;
  }
}
