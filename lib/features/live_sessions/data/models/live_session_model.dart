class LiveSessionModel {
  final String id;
  final String title;
  final String description;
  final String url;
  final String date;
  final String createdAt;

  const LiveSessionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.date,
    required this.createdAt,
  });

  LiveSessionModel copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    String? date,
    String? createdAt,
  }) {
    return LiveSessionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'date': date,
      'createdAt': createdAt,
    };
  }

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    return LiveSessionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      date: json['date'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'LiveSessionModel(id: $id, title: $title, url: $url, date: $date, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveSessionModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.url == url &&
        other.date == date &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, description, url, date, createdAt);
  }
}
