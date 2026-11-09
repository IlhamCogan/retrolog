class MotorModel {
  final int? id;
  final String nickname;
  final String name;
  final String year;
  final String plate;
  final String engine;
  final String status;
  final String progress;

  MotorModel({
    this.id,
    required this.nickname,
    required this.name,
    required this.year,
    required this.plate,
    required this.engine,
    required this.status,
    required this.progress,
  });

  factory MotorModel.fromMap(Map<String, dynamic> map) {
    return MotorModel(
      id: map['id'] as int?,
      nickname: map['nickname'] ?? map['name'] ?? 'Motor Retro',
      name: map['name'] ?? 'Tanpa Nama',
      year: map['year'] ?? '-',
      plate: map['plate'] ?? '-',
      engine: map['engine'] ?? '100 cc',
      status: map['status'] ?? 'Sedang Direstorasi',
      progress: map['progress'] ?? '0%',
    );
  }
}