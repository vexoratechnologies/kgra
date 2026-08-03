/// UserModel represents a registered user in the My KGRA application.
/// 
/// It encapsulates registration details and authorization flags.
class UserModel {
  final String uid;
  final String name;
  final String phoneNumber;
  final String? designation;
  final String? institution;
  final String? profileImageId;
  final bool isApproved;
  final String status; // e.g. 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  
  // Updated fields
  final String? zone;
  final String? dateOfBirth;
  final String? dateOfJoin;
  final String? membershipId;
  final String? dateOfRetirement;
  final String? reviewedByName;
  final String? reviewedById;
  final String? reviewedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    this.designation,
    this.institution,
    this.profileImageId,
    this.isApproved = false,
    this.status = 'pending',
    required this.createdAt,
    this.zone,
    this.dateOfBirth,
    this.dateOfJoin,
    this.membershipId,
    this.dateOfRetirement,
    this.reviewedByName,
    this.reviewedById,
    this.reviewedAt,
  });

  /// Creates a copy of the UserModel with replaced fields.
  UserModel copyWith({
    String? uid,
    String? name,
    String? phoneNumber,
    String? designation,
    String? institution,
    String? profileImageId,
    bool? isApproved,
    String? status,
    DateTime? createdAt,
    String? zone,
    String? dateOfBirth,
    String? dateOfJoin,
    String? membershipId,
    String? dateOfRetirement,
    String? reviewedByName,
    String? reviewedById,
    String? reviewedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      designation: designation ?? this.designation,
      institution: institution ?? this.institution,
      profileImageId: profileImageId ?? this.profileImageId,
      isApproved: isApproved ?? this.isApproved,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      zone: zone ?? this.zone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfJoin: dateOfJoin ?? this.dateOfJoin,
      membershipId: membershipId ?? this.membershipId,
      dateOfRetirement: dateOfRetirement ?? this.dateOfRetirement,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedById: reviewedById ?? this.reviewedById,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  /// Creates a UserModel instance from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    DateTime parsedDate;
    final rawCreatedAt = json['createdAt'];
    if (rawCreatedAt == null) {
      parsedDate = DateTime.now();
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      // Handle Firestore Timestamp dynamically
      try {
        parsedDate = (rawCreatedAt as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedDate = DateTime.now();
      }
    }

    final rawUid = json['uid']?.toString() ?? '';
    final effectiveUid = rawUid.isNotEmpty ? rawUid : (docId ?? '');

    return UserModel(
      uid: effectiveUid,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      designation: json['designation'] as String?,
      institution: json['institution'] as String?,
      profileImageId: json['profileImageId'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      createdAt: parsedDate,
      zone: json['zone'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      dateOfJoin: json['dateOfJoin'] as String?,
      membershipId: json['membershipId'] as String?,
      dateOfRetirement: json['dateOfRetirement'] as String?,
      reviewedByName: json['reviewedByName'] as String?,
      reviewedById: json['reviewedById'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
    );
  }

  /// Converts the UserModel instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phoneNumber': phoneNumber,
      'designation': designation,
      'institution': institution,
      'profileImageId': profileImageId,
      'isApproved': isApproved,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'zone': zone,
      'dateOfBirth': dateOfBirth,
      'dateOfJoin': dateOfJoin,
      'membershipId': membershipId,
      'dateOfRetirement': dateOfRetirement,
      'reviewedByName': reviewedByName,
      'reviewedById': reviewedById,
      'reviewedAt': reviewedAt,
    };
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, phoneNumber: $phoneNumber, designation: $designation, institution: $institution, profileImageId: $profileImageId, isApproved: $isApproved, status: $status, createdAt: $createdAt, zone: $zone, dateOfBirth: $dateOfBirth, dateOfJoin: $dateOfJoin, membershipId: $membershipId, dateOfRetirement: $dateOfRetirement, reviewedByName: $reviewedByName, reviewedById: $reviewedById, reviewedAt: $reviewedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.uid == uid &&
      other.name == name &&
      other.phoneNumber == phoneNumber &&
      other.designation == designation &&
      other.institution == institution &&
      other.profileImageId == profileImageId &&
      other.isApproved == isApproved &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.zone == zone &&
      other.dateOfBirth == dateOfBirth &&
      other.dateOfJoin == dateOfJoin &&
      other.membershipId == membershipId &&
      other.dateOfRetirement == dateOfRetirement &&
      other.reviewedByName == reviewedByName &&
      other.reviewedById == reviewedById &&
      other.reviewedAt == reviewedAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
      name.hashCode ^
      phoneNumber.hashCode ^
      designation.hashCode ^
      institution.hashCode ^
      profileImageId.hashCode ^
      isApproved.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      zone.hashCode ^
      dateOfBirth.hashCode ^
      dateOfJoin.hashCode ^
      membershipId.hashCode ^
      dateOfRetirement.hashCode ^
      reviewedByName.hashCode ^
      reviewedById.hashCode ^
      reviewedAt.hashCode;
  }
}
