class MeetingMinutesModel {
  final String id;
  final String title;
  final String date;
  final String pdfName;
  final String pdfUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String createdAt;

  const MeetingMinutesModel({
    required this.id,
    required this.title,
    required this.date,
    required this.pdfName,
    required this.pdfUrl,
    this.status = 'pending',
    required this.createdAt,
  });

  MeetingMinutesModel copyWith({
    String? id,
    String? title,
    String? date,
    String? pdfName,
    String? pdfUrl,
    String? status,
    String? createdAt,
  }) {
    return MeetingMinutesModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      pdfName: pdfName ?? this.pdfName,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'pdfName': pdfName,
      'pdfUrl': pdfUrl,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory MeetingMinutesModel.fromJson(Map<String, dynamic> json) {
    return MeetingMinutesModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      pdfName: json['pdfName'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'MeetingMinutesModel(id: $id, title: $title, date: $date, pdfName: $pdfName, pdfUrl: $pdfUrl, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeetingMinutesModel &&
        other.id == id &&
        other.title == title &&
        other.date == date &&
        other.pdfName == pdfName &&
        other.pdfUrl == pdfUrl &&
        other.status == status &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, date, pdfName, pdfUrl, status, createdAt);
  }
}
