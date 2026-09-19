class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String routingPath;
  final String createdAt;
  final String? targetUserId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.routingPath,
    required this.createdAt,
    this.targetUserId,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? routingPath,
    String? createdAt,
    String? targetUserId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      routingPath: routingPath ?? this.routingPath,
      createdAt: createdAt ?? this.createdAt,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'routingPath': routingPath,
      'createdAt': createdAt,
      if (targetUserId != null) 'targetUserId': targetUserId,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      routingPath: json['routingPath'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      targetUserId: json['targetUserId'] as String?,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, body: $body, routingPath: $routingPath, createdAt: $createdAt, targetUserId: $targetUserId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.routingPath == routingPath &&
        other.createdAt == createdAt &&
        other.targetUserId == targetUserId;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, body, routingPath, createdAt, targetUserId);
  }
}
