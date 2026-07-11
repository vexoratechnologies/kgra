class GovernmentOrderModel {
  final String id;
  final String title;
  final String orderNumber;
  final String date;
  final String pdfName;
  final String pdfUrl;
  final String createdAt;

  const GovernmentOrderModel({
    required this.id,
    required this.title,
    required this.orderNumber,
    required this.date,
    required this.pdfName,
    required this.pdfUrl,
    required this.createdAt,
  });

  GovernmentOrderModel copyWith({
    String? id,
    String? title,
    String? orderNumber,
    String? date,
    String? pdfName,
    String? pdfUrl,
    String? createdAt,
  }) {
    return GovernmentOrderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      orderNumber: orderNumber ?? this.orderNumber,
      date: date ?? this.date,
      pdfName: pdfName ?? this.pdfName,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'orderNumber': orderNumber,
      'date': date,
      'pdfName': pdfName,
      'pdfUrl': pdfUrl,
      'createdAt': createdAt,
    };
  }

  factory GovernmentOrderModel.fromJson(Map<String, dynamic> json) {
    return GovernmentOrderModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      date: json['date'] as String? ?? '',
      pdfName: json['pdfName'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'GovernmentOrderModel(id: $id, title: $title, orderNumber: $orderNumber, date: $date, pdfName: $pdfName, pdfUrl: $pdfUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GovernmentOrderModel &&
        other.id == id &&
        other.title == title &&
        other.orderNumber == orderNumber &&
        other.date == date &&
        other.pdfName == pdfName &&
        other.pdfUrl == pdfUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, orderNumber, date, pdfName, pdfUrl, createdAt);
  }
}
