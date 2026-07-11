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
  final String? membershipId;
  final String? dateOfRetirement;

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
    this.membershipId,
    this.dateOfRetirement,
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
    String? membershipId,
    String? dateOfRetirement,
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
      membershipId: membershipId ?? this.membershipId,
      dateOfRetirement: dateOfRetirement ?? this.dateOfRetirement,
    );
  }

  /// Creates a UserModel instance from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
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

    return UserModel(
      uid: json['uid'] as String? ?? '',
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
      membershipId: json['membershipId'] as String?,
      dateOfRetirement: json['dateOfRetirement'] as String?,
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
      'membershipId': membershipId,
      'dateOfRetirement': dateOfRetirement,
    };
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, phoneNumber: $phoneNumber, designation: $designation, institution: $institution, profileImageId: $profileImageId, isApproved: $isApproved, status: $status, createdAt: $createdAt, zone: $zone, dateOfBirth: $dateOfBirth, membershipId: $membershipId, dateOfRetirement: $dateOfRetirement)';
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
      other.membershipId == membershipId &&
      other.dateOfRetirement == dateOfRetirement;
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
      membershipId.hashCode ^
      dateOfRetirement.hashCode;
  }
}
