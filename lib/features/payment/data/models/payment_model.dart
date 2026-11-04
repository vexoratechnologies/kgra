import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an individual payment attempt logged to the PAYMENT_ATTEMPTS collection
class PaymentAttemptModel {
  final String attemptId;
  final String orderId;
  final String? receipt;
  final String? receiptNumber;
  final String? userId;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? membershipId;
  final String? designation;
  final String? institution;
  final String? zone;
  final double amount;
  final String currency;
  final String status; // 'INITIATED', 'SUCCESS', 'FAILED', 'CANCELLED'
  final String purpose;
  final String? financialYear;
  final String? failureReason;
  final String? paymentId;
  final String? paymentMethod;
  final String? platform;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentAttemptModel({
    required this.attemptId,
    required this.orderId,
    this.receipt,
    this.receiptNumber,
    this.userId,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.membershipId,
    this.designation,
    this.institution,
    this.zone,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    required this.purpose,
    this.financialYear,
    this.failureReason,
    this.paymentId,
    this.paymentMethod,
    this.platform,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentAttemptModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentAttemptModel(
      attemptId: docId,
      orderId: map['orderId'] as String? ?? docId,
      receipt: map['receipt'] as String?,
      receiptNumber: map['receiptNumber'] as String?,
      userId: map['userId'] as String?,
      userName: map['userName'] as String?,
      userPhone: map['userPhone'] as String?,
      userEmail: map['userEmail'] as String?,
      membershipId: map['membershipId'] as String?,
      designation: map['designation'] as String?,
      institution: map['institution'] as String?,
      zone: map['zone'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'INR',
      status: map['status'] as String? ?? 'INITIATED',
      purpose: map['purpose'] as String? ?? 'ANNUAL_MEMBERSHIP_FEE',
      financialYear: map['financialYear'] as String?,
      failureReason: map['failureReason'] as String?,
      paymentId: map['paymentId'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      platform: map['platform'] as String?,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attemptId': attemptId,
      'orderId': orderId,
      'receipt': receipt,
      'receiptNumber': receiptNumber,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'membershipId': membershipId,
      'designation': designation,
      'institution': institution,
      'zone': zone,
      'amount': amount,
      'currency': currency,
      'status': status,
      'purpose': purpose,
      'financialYear': financialYear,
      'failureReason': failureReason,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'platform': platform,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}

/// Represents a verified completed transaction logged to the PAYMENTS collection with rich details
class PaymentTransactionModel {
  final String paymentId;
  final String orderId;
  final String? receiptNumber;
  final String? attemptId;
  final String? userId;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? membershipId;
  final String? designation;
  final String? institution;
  final String? zone;
  final double amount;
  final String currency;
  final String? signature;
  final String status; // 'SUCCESS'
  final String purpose;
  final String? purposeLabel;
  final String? financialYear;
  final String? paymentMethod; // 'upi', 'card', 'netbanking', 'wallet'
  final String? vpa;
  final String? membershipType; // 'ANNUAL', 'LIFE'
  final String? membershipValidUntil;
  final String? platform;
  final DateTime? paidAt;
  final DateTime? verifiedAt;

  PaymentTransactionModel({
    required this.paymentId,
    required this.orderId,
    this.receiptNumber,
    this.attemptId,
    this.userId,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.membershipId,
    this.designation,
    this.institution,
    this.zone,
    required this.amount,
    this.currency = 'INR',
    this.signature,
    required this.status,
    required this.purpose,
    this.purposeLabel,
    this.financialYear,
    this.paymentMethod,
    this.vpa,
    this.membershipType,
    this.membershipValidUntil,
    this.platform,
    this.paidAt,
    this.verifiedAt,
  });

  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentTransactionModel(
      paymentId: docId,
      orderId: map['orderId'] as String? ?? '',
      receiptNumber: map['receiptNumber'] as String?,
      attemptId: map['attemptId'] as String?,
      userId: map['userId'] as String?,
      userName: map['userName'] as String?,
      userPhone: map['userPhone'] as String?,
      userEmail: map['userEmail'] as String?,
      membershipId: map['membershipId'] as String?,
      designation: map['designation'] as String?,
      institution: map['institution'] as String?,
      zone: map['zone'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'INR',
      signature: map['signature'] as String?,
      status: map['status'] as String? ?? 'SUCCESS',
      purpose: map['purpose'] as String? ?? 'ANNUAL_MEMBERSHIP_FEE',
      purposeLabel: map['purposeLabel'] as String?,
      financialYear: map['financialYear'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      vpa: map['vpa'] as String?,
      membershipType: map['membershipType'] as String?,
      membershipValidUntil: map['membershipValidUntil'] as String?,
      platform: map['platform'] as String?,
      paidAt: (map['paidAt'] is Timestamp)
          ? (map['paidAt'] as Timestamp).toDate()
          : null,
      verifiedAt: (map['verifiedAt'] is Timestamp)
          ? (map['verifiedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'receiptNumber': receiptNumber,
      'attemptId': attemptId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'membershipId': membershipId,
      'designation': designation,
      'institution': institution,
      'zone': zone,
      'amount': amount,
      'currency': currency,
      'signature': signature,
      'status': status,
      'purpose': purpose,
      'purposeLabel': purposeLabel,
      'financialYear': financialYear,
      'paymentMethod': paymentMethod,
      'vpa': vpa,
      'membershipType': membershipType,
      'membershipValidUntil': membershipValidUntil,
      'platform': platform,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : FieldValue.serverTimestamp(),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
