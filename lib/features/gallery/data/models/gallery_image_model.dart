class GalleryImageModel {
  final String id;
  final String title;
  final String imageUrl;
  final String createdAt;

  const GalleryImageModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.createdAt,
  });

  GalleryImageModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? createdAt,
  }) {
    return GalleryImageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }

  factory GalleryImageModel.fromJson(Map<String, dynamic> json) {
    return GalleryImageModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'GalleryImageModel(id: $id, title: $title, imageUrl: $imageUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryImageModel &&
        other.id == id &&
        other.title == title &&
        other.imageUrl == imageUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, imageUrl, createdAt);
  }
}
