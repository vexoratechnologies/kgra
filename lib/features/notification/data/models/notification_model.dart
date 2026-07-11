class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String routingPath;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.routingPath,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? routingPath,
    String? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      routingPath: routingPath ?? this.routingPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'routingPath': routingPath,
      'createdAt': createdAt,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      routingPath: json['routingPath'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, body: $body, routingPath: $routingPath, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.routingPath == routingPath &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, body, routingPath, createdAt);
  }
}
