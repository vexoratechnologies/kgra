/// AdminModel represents an administrative user in the My KGRA application.
/// 
/// It encapsulates login credentials and role details (super admin vs zonal admin).
class AdminModel {
  final String username;
  final String password;
  final String role; // 'super_admin' or 'zonal_admin'
  final String? zone; // assigned zone (only for zonal_admin)
  final String createdAt;

  const AdminModel({
    required this.username,
    required this.password,
    required this.role,
    this.zone,
    required this.createdAt,
  });

  AdminModel copyWith({
    String? username,
    String? password,
    String? role,
    String? zone,
    String? createdAt,
  }) {
    return AdminModel(
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      zone: zone ?? this.zone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'zone': zone,
      'createdAt': createdAt,
    };
  }

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      role: json['role'] as String? ?? 'zonal_admin',
      zone: json['zone'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'AdminModel(username: $username, role: $role, zone: $zone, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminModel &&
        other.username == username &&
        other.password == password &&
        other.role == role &&
        other.zone == zone &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(username, password, role, zone, createdAt);
  }
}
