class LogModel {
  final int? id;
  final String title;
  final String category;
  final String date;
  final int cost;
  final int? motorId;

  LogModel({
    this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.cost,
    this.motorId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'date': date,
      'cost': cost,
      'motor_id': motorId, // 👈 Disimpan ke kolom motor_id SQLite
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      category: map['category'] ?? 'Umum',
      date: map['date'] ?? 'Hari Ini',
      cost: map['cost'] as int? ?? 0,
      motorId: map['motor_id'],
    );
  }
}