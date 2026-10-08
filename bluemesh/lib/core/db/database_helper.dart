import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bluemesh_attendance_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        name TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roll_number TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        class_section TEXT,
        email TEXT,
        phone TEXT,
        is_fingerprint_registered INTEGER DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_name TEXT,
        start_time TEXT,
        end_time TEXT,
        heartbeat_interval_ms INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        roll_number TEXT,
        status TEXT,
        fingerprint_verified INTEGER,
        first_seen_at TEXT,
        last_seen_at TEXT,
        attended_seconds INTEGER,
        session_total_seconds INTEGER,
        attendance_percentage REAL,
        ping_count INTEGER,
        missed_count INTEGER,
        rssi INTEGER,
        FOREIGN KEY(session_id) REFERENCES sessions(id)
      );
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS attendance');
      await db.execute('''
        CREATE TABLE attendance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER,
          roll_number TEXT,
          status TEXT,
          fingerprint_verified INTEGER,
          first_seen_at TEXT,
          last_seen_at TEXT,
          attended_seconds INTEGER,
          session_total_seconds INTEGER,
          attendance_percentage REAL,
          ping_count INTEGER,
          missed_count INTEGER,
          rssi INTEGER,
          FOREIGN KEY(session_id) REFERENCES sessions(id)
        );
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE students ADD COLUMN email TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE students ADD COLUMN phone TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE students ADD COLUMN is_fingerprint_registered INTEGER DEFAULT 1;');
      } catch (_) {}
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
