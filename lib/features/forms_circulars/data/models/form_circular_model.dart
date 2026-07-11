class FormCircularModel {
  final String id;
  final String title;
  final String? circularNumber;
  final String date;
  final String pdfName;
  final String pdfUrl;
  final String? externalUrl;
  final String createdAt;

  const FormCircularModel({
    required this.id,
    required this.title,
    this.circularNumber,
    required this.date,
    required this.pdfName,
    required this.pdfUrl,
    this.externalUrl,
    required this.createdAt,
  });

  FormCircularModel copyWith({
    String? id,
    String? title,
    String? circularNumber,
    String? date,
    String? pdfName,
    String? pdfUrl,
    String? externalUrl,
    String? createdAt,
  }) {
    return FormCircularModel(
      id: id ?? this.id,
      title: title ?? this.title,
      circularNumber: circularNumber ?? this.circularNumber,
      date: date ?? this.date,
      pdfName: pdfName ?? this.pdfName,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'circularNumber': circularNumber,
      'date': date,
      'pdfName': pdfName,
      'pdfUrl': pdfUrl,
      'externalUrl': externalUrl,
      'createdAt': createdAt,
    };
  }

  factory FormCircularModel.fromJson(Map<String, dynamic> json) {
    return FormCircularModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      circularNumber: json['circularNumber'] as String?,
      date: json['date'] as String? ?? '',
      pdfName: json['pdfName'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String? ?? '',
      externalUrl: json['externalUrl'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'FormCircularModel(id: $id, title: $title, circularNumber: $circularNumber, date: $date, pdfName: $pdfName, pdfUrl: $pdfUrl, externalUrl: $externalUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormCircularModel &&
        other.id == id &&
        other.title == title &&
        other.circularNumber == circularNumber &&
        other.date == date &&
        other.pdfName == pdfName &&
        other.pdfUrl == pdfUrl &&
        other.externalUrl == externalUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, circularNumber, date, pdfName, pdfUrl, externalUrl, createdAt);
  }
}
