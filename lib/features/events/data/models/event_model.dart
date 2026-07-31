class EventModel {
  final String id;
  final String title;
  final String location;
  final String date; // yyyy-MM-dd
  final String createdAt;
  final String time;
  final String link;

  const EventModel({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.createdAt,
    this.time = '10:30 AM',
    this.link = '',
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? location,
    String? date,
    String? createdAt,
    String? time,
    String? link,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      time: time ?? this.time,
      link: link ?? this.link,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'createdAt': createdAt,
      'time': time,
      'link': link,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: json['date'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      time: json['time'] as String? ?? '10:30 AM',
      link: json['link'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, location: $location, date: $date, createdAt: $createdAt, time: $time, link: $link)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel &&
        other.id == id &&
        other.title == title &&
        other.location == location &&
        other.date == date &&
        other.createdAt == createdAt &&
        other.time == time &&
        other.link == link;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, location, date, createdAt, time, link);
  }
}
