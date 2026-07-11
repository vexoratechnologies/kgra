class VideoProgressModel {
  final String videoId;
  final String userId;
  final int watchedSeconds;
  final bool isCompleted;
  final String lastUpdated;

  const VideoProgressModel({
    required this.videoId,
    required this.userId,
    required this.watchedSeconds,
    required this.isCompleted,
    required this.lastUpdated,
  });

  VideoProgressModel copyWith({
    String? videoId,
    String? userId,
    int? watchedSeconds,
    bool? isCompleted,
    String? lastUpdated,
  }) {
    return VideoProgressModel(
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'userId': userId,
      'watchedSeconds': watchedSeconds,
      'isCompleted': isCompleted,
      'lastUpdated': lastUpdated,
    };
  }

  factory VideoProgressModel.fromJson(Map<String, dynamic> json) {
    return VideoProgressModel(
      videoId: json['videoId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      watchedSeconds: json['watchedSeconds'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'VideoProgressModel(videoId: $videoId, userId: $userId, watchedSeconds: $watchedSeconds, isCompleted: $isCompleted, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoProgressModel &&
        other.videoId == videoId &&
        other.userId == userId &&
        other.watchedSeconds == watchedSeconds &&
        other.isCompleted == isCompleted &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return Object.hash(videoId, userId, watchedSeconds, isCompleted, lastUpdated);
  }
}
