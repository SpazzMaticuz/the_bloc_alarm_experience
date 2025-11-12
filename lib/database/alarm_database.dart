import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for alarms.
/// Schema:
/// - id (INTEGER PRIMARY KEY AUTOINCREMENT)
/// - minutesSinceMidnight (INTEGER: 0–1439)
/// - isActive (INTEGER: 0/1)
/// - label (TEXT)
/// - days (TEXT)
/// - notificationKey (TEXT)
/// - music (TEXT)
class AlarmDatabase {
  static final AlarmDatabase instance = AlarmDatabase._init();
  static Database? _database;

  AlarmDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('alarms.db');
    return _database!;
  }

  /// Initialize and open database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      onCreate: _createDB,
      version: 1, // ✅ back to single-version baseline
    );
  }

  /// Create table (fresh install)
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        minutesSinceMidnight INTEGER NOT NULL,
        isActive INTEGER NOT NULL,
        label TEXT,
        days TEXT,
        notificationKey TEXT,
        music TEXT
      )
    ''');
  }

  // --- CRUD operations ---

  Future<int> create(Map<String, dynamic> alarm) async {
    final db = await instance.database;
    return await db.insert('alarms', alarm);
  }

  Future<Map<String, dynamic>?> read(int id) async {
    final db = await instance.database;
    final res = await db.query(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<Map<String, dynamic>>> readAll() async {
    final db = await instance.database;
    return await db.query(
      'alarms',
      orderBy: 'minutesSinceMidnight ASC',
    );
  }

  Future<int> update(int id, Map<String, dynamic> alarm) async {
    final db = await instance.database;
    return await db.update(
      'alarms',
      alarm,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
