class UpdateModel {
  final String id;
  final String title;
  final String content;
  final String date;
  final String createdAt;

  const UpdateModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.createdAt,
  });

  UpdateModel copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    String? createdAt,
  }) {
    return UpdateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'createdAt': createdAt,
    };
  }

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      date: json['date'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'UpdateModel(id: $id, title: $title, date: $date, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateModel &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.date == date &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, content, date, createdAt);
  }
}
