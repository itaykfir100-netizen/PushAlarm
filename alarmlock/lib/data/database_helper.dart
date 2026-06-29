import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alarm.dart';
import '../models/workout_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'pushalarm.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE alarms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hour INTEGER NOT NULL,
            minute INTEGER NOT NULL,
            label TEXT NOT NULL DEFAULT '',
            days TEXT NOT NULL,
            push_up_count INTEGER NOT NULL,
            is_enabled INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            alarm_id INTEGER NOT NULL,
            date INTEGER NOT NULL,
            push_ups_completed INTEGER NOT NULL,
            target_push_ups INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ---------- Alarms ----------

  Future<int> insertAlarm(Alarm alarm) async {
    final db = await database;
    return db.insert('alarms', alarm.toMap());
  }

  Future<List<Alarm>> getAlarms() async {
    final db = await database;
    final rows = await db.query('alarms', orderBy: 'hour ASC, minute ASC');
    return rows.map(Alarm.fromMap).toList();
  }

  Future<Alarm?> getAlarm(int id) async {
    final db = await database;
    final rows = await db.query('alarms', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Alarm.fromMap(rows.first);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final db = await database;
    await db.update('alarms', alarm.toMap(), where: 'id = ?', whereArgs: [alarm.id]);
  }

  Future<void> deleteAlarm(int id) async {
    final db = await database;
    await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Workout Logs ----------

  Future<void> insertLog(WorkoutLog log) async {
    final db = await database;
    await db.insert('workout_logs', log.toMap());
  }

  Future<List<WorkoutLog>> getLogs() async {
    final db = await database;
    final rows = await db.query('workout_logs', orderBy: 'date DESC');
    return rows.map(WorkoutLog.fromMap).toList();
  }

  Future<List<WorkoutLog>> getLogsForLastDays(int days) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final rows = await db.query(
      'workout_logs',
      where: 'date >= ?',
      whereArgs: [since],
      orderBy: 'date ASC',
    );
    return rows.map(WorkoutLog.fromMap).toList();
  }
}
