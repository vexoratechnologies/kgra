class AdModel {
  final String id;
  final String imageUrl;
  final String? targetUrl;
  final String createdAt;

  const AdModel({
    required this.id,
    required this.imageUrl,
    this.targetUrl,
    required this.createdAt,
  });

  AdModel copyWith({
    String? id,
    String? imageUrl,
    String? targetUrl,
    String? createdAt,
  }) {
    return AdModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'createdAt': createdAt,
    };
  }

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      targetUrl: json['targetUrl'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'AdModel(id: $id, imageUrl: $imageUrl, targetUrl: $targetUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdModel &&
        other.id == id &&
        other.imageUrl == imageUrl &&
        other.targetUrl == targetUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, imageUrl, targetUrl, createdAt);
  }
}
