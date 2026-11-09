import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/motor_model.dart';
import '../models/log_model.dart';

class DBHelper {
  static Database? _database;

  static final List<MotorModel> _webMotors = [
    MotorModel(
      id: 1,
      nickname: 'Legasi',
      name: 'Honda Astrea Legenda',
      year: '2002',
      plate: 'H 4821 BG',
      engine: '100 cc',
      status: 'Sedang Direstorasi',
      progress: '75%',
    ),
  ];

  static final List<LogModel> _webLogs = [
    LogModel(
      id: 1,
      title: 'Repaint Bodi Motor',
      category: 'Bodi',
      date: '2026-09-15',
      cost: 1500000,
      motorId: 1,
    ),
    LogModel(
      id: 2,
      title: 'Pasang Velg Jari-jari Hitam',
      category: 'Kaki-kaki',
      date: '2026-09-10',
      cost: 850000,
      motorId: 1,
    ),
    LogModel(
      id: 3,
      title: 'Fitment Ban Donat Corsa R46',
      category: 'Kaki-kaki',
      date: '2026-09-05',
      cost: 300000,
      motorId: 1,
    ),
  ];

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'retrolog.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE motors(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT,
        name TEXT,
        year TEXT,
        plate TEXT,
        engine TEXT,
        status TEXT,
        progress TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        category TEXT,
        date TEXT,
        cost INTEGER,
        motor_id INTEGER
      )
    ''');

    await db.insert('motors', {
      'nickname': 'Legasi',
      'name': 'Honda Astrea Legenda',
      'year': '2002',
      'plate': 'H 4821 BG',
      'engine': '100 cc',
      'status': 'Sedang Direstorasi',
      'progress': '75%',
    });

    await db.insert('logs', {
      'title': 'Repaint Bodi Motor',
      'category': 'Bodi',
      'date': '2026-09-15',
      'cost': 1500000,
      'motor_id': 1,
    });
  }

  // ==========================================
  // FUNGSI LOGBOOK RESTORASI
  // ==========================================
  Future<List<LogModel>> getLogs() async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 100));
      _webLogs.sort((a, b) => b.date.compareTo(a.date));
      return List.from(_webLogs);
    }
    final db = await database;
    if (db == null) return _webLogs;
    final List<Map<String, dynamic>> maps = await db.query('logs', orderBy: 'date DESC, id DESC');
    return List.generate(maps.length, (i) => LogModel.fromMap(maps[i]));
  }

  // Mengambil data log spesifik untuk satu motor
  Future<List<LogModel>> getLogsByMotorId(int motorId) async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _webLogs.where((item) => item.motorId == motorId).toList();
    }
    final db = await database;
    if (db == null) return _webLogs;
    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      where: 'motor_id = ?',
      whereArgs: [motorId],
      orderBy: 'date DESC, id DESC',
    );
    return List.generate(maps.length, (i) => LogModel.fromMap(maps[i]));
  }

  Future<int> insertLog(LogModel log) async {
    if (kIsWeb) {
      final newLog = LogModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: log.title,
        category: log.category,
        date: log.date,
        cost: log.cost,
        motorId: log.motorId,
      );
      _webLogs.insert(0, newLog);
      return newLog.id!;
    }
    final db = await database;
    if (db == null) return 0;

    // 👈 SANGAT PENTING: motor_id dimasukkan ke map pencatatan SQLite!
    return await db.insert('logs', {
      'title': log.title,
      'category': log.category,
      'date': log.date,
      'cost': log.cost,
      'motor_id': log.motorId, // 👈 Kunci penyambung log ke motor terpilih
    });
  }

  Future<int> deleteLog(int id) async {
    if (kIsWeb) {
      _webLogs.removeWhere((item) => item.id == id);
      return id;
    }
    final db = await database;
    if (db == null) return 0;
    return await db.delete('logs', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // FUNGSI GARASI MOTOR
  // ==========================================
  Future<List<MotorModel>> getMotors() async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 100));
      return List.from(_webMotors);
    }
    final db = await database;
    if (db == null) return _webMotors;
    final List<Map<String, dynamic>> maps = await db.query('motors', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => MotorModel.fromMap(maps[i]));
  }

  Future<int> insertMotor(MotorModel motor) async {
    if (kIsWeb) {
      final newMotor = MotorModel(
        id: DateTime.now().millisecondsSinceEpoch,
        nickname: motor.nickname,
        name: motor.name,
        year: motor.year,
        plate: motor.plate,
        engine: motor.engine,
        status: motor.status,
        progress: motor.progress,
      );
      _webMotors.insert(0, newMotor);
      return newMotor.id!;
    }
    final db = await database;
    if (db == null) return 0;
    return await db.insert('motors', {
      'nickname': motor.nickname,
      'name': motor.name,
      'year': motor.year,
      'plate': motor.plate,
      'engine': motor.engine,
      'status': motor.status,
      'progress': motor.progress,
    });
  }

  Future<int> deleteMotor(int id) async {
    if (kIsWeb) {
      _webMotors.removeWhere((item) => item.id == id);
      return id;
    }
    final db = await database;
    if (db == null) return 0;
    return await db.delete('motors', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> autoDeleteOldLogs({int daysOlderThan = 365}) async {
    final db = await database;
    if (db == null) return 0;

    DateTime thresholdDate = DateTime.now().subtract(Duration(days: daysOlderThan));
    String thresholdStr = thresholdDate.toIso8601String().split('T')[0];

    return await db.delete(
      'logs',
      where: 'date < ?',
      whereArgs: [thresholdStr],
    );
  }
}