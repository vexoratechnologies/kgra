class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int duration; // in seconds
  final String createdAt;
  final String section;
  final String zone;

  const VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl = '',
    required this.duration,
    required this.createdAt,
    this.section = 'all',
    this.zone = '',
  });

  VideoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
    String? createdAt,
    String? section,
    String? zone,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      section: section ?? this.section,
      zone: zone ?? this.zone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'createdAt': createdAt,
      'section': section,
      'zone': zone,
    };
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      section: json['section'] as String? ?? 'all',
      zone: json['zone'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, duration: $duration, createdAt: $createdAt, section: $section, zone: $zone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.videoUrl == videoUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.duration == duration &&
        other.createdAt == createdAt &&
        other.section == section &&
        other.zone == zone;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, description, videoUrl, thumbnailUrl, duration, createdAt, section, zone);
  }
}
