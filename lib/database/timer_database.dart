import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';

/// Local SQLite database for Timers.
/// Schema:
/// - id (INTEGER PRIMARY KEY AUTOINCREMENT)
/// - durationSeconds (INTEGER: The total initial duration of the timer)
/// - isActive (INTEGER: 0/1, whether the timer is running/scheduled)
class TimerDatabase {
  static final TimerDatabase instance = TimerDatabase._init();
  static Database? _database;
  static const String _tableName = 'timers';

  TimerDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('timers.db');
    return _database!;
  }

  /// Initialize and open database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    log('Initializing Timer DB at: $path');

    return await openDatabase(
      path,
      onCreate: _createDB,
      version: 1,
    );
  }

  /// Create table (fresh install)
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        durationSeconds INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    log('Timer table created successfully.');
  }

  // --- CRUD operations ---

  /// Creates a new timer entry. Returns the ID of the new row.
  Future<int> create(int durationSeconds) async {
    final db = await instance.database;
    final id = await db.insert(_tableName, {
      'durationSeconds': durationSeconds,
      'isActive': 1, // Start active
    });
    log('Timer created with ID: $id and duration: $durationSeconds');
    return id;
  }

  /// Reads all stored timers.
  Future<List<Map<String, dynamic>>> readAll() async {
    final db = await instance.database;
    return await db.query(_tableName, orderBy: 'id ASC');
  }

  /// Deletes a timer by ID.
  Future<int> delete(int id) async {
    final db = await instance.database;
    final count = await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    log('Timer with ID $id deleted. Rows affected: $count');
    return count;
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}