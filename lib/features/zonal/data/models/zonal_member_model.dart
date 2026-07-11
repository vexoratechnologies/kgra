class ZonalMemberModel {
  final String id;
  final String name;
  final String designation;
  final String phoneNumber;
  final String email;
  final String zone;
  final String? photoBase64;
  final String createdAt;

  const ZonalMemberModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.phoneNumber,
    required this.email,
    required this.zone,
    this.photoBase64,
    required this.createdAt,
  });

  ZonalMemberModel copyWith({
    String? id,
    String? name,
    String? designation,
    String? phoneNumber,
    String? email,
    String? zone,
    String? photoBase64,
    String? createdAt,
  }) {
    return ZonalMemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      zone: zone ?? this.zone,
      photoBase64: photoBase64 ?? this.photoBase64,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'designation': designation,
      'phoneNumber': phoneNumber,
      'email': email,
      'zone': zone,
      'photoBase64': photoBase64,
      'createdAt': createdAt,
    };
  }

  factory ZonalMemberModel.fromJson(Map<String, dynamic> json) {
    return ZonalMemberModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      photoBase64: json['photoBase64'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'ZonalMemberModel(id: $id, name: $name, designation: $designation, zone: $zone, phoneNumber: $phoneNumber, email: $email, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZonalMemberModel &&
        other.id == id &&
        other.name == name &&
        other.designation == designation &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.zone == zone &&
        other.photoBase64 == photoBase64 &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, designation, phoneNumber, email, zone, photoBase64, createdAt);
  }
}
