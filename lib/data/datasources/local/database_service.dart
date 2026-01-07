import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database service for SQLite operations
class DatabaseService {
  static Database? _database;

  /// Gets database instance (singleton pattern)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'gpa_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Students table
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        program TEXT NOT NULL,
        gpa_scale REAL NOT NULL,
        enrollment_date TEXT NOT NULL,
        total_credits_required INTEGER NOT NULL,
        retake_policy TEXT NOT NULL
      )
    ''');

    // Semesters table
    await db.execute('''
      CREATE TABLE semesters (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_semesters_student ON semesters(student_id)
    ''');

    // Courses table
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        semester_id TEXT NOT NULL,
        course_code TEXT NOT NULL,
        course_name TEXT NOT NULL,
        credits INTEGER NOT NULL,
        letter_grade TEXT,
        grade_point REAL,
        attempt_number INTEGER NOT NULL DEFAULT 1,
        course_type TEXT NOT NULL,
        FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_courses_semester ON courses(semester_id)
    ''');

    // GPA records table
    await db.execute('''
      CREATE TABLE gpa_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        calculated_at TEXT NOT NULL,
        cumulative_gpa REAL NOT NULL,
        semester_gpa REAL,
        total_credits_attempted INTEGER NOT NULL,
        total_credits_earned INTEGER NOT NULL,
        total_quality_points REAL NOT NULL,
        semester_id TEXT,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_gpa_records_student ON gpa_records(student_id, calculated_at)
    ''');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}