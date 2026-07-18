class EventModel {
  final String id;
  final String title;
  final String location;
  final String date; // yyyy-MM-dd
  final String createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.createdAt,
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? location,
    String? date,
    String? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'createdAt': createdAt,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: json['date'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, location: $location, date: $date, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel &&
        other.id == id &&
        other.title == title &&
        other.location == location &&
        other.date == date &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, location, date, createdAt);
  }
}
