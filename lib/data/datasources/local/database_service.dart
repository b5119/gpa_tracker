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
      version: 5, // Incremented version for dropped-assessment support
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Grading configurations table
    await db.execute('''
      CREATE TABLE grading_configs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        system_type TEXT NOT NULL,
        max_gpa REAL NOT NULL,
        min_gpa REAL NOT NULL DEFAULT 0.0,
        grade_to_point_map TEXT NOT NULL,
        classifications TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        last_modified TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_grading_configs_default 
      ON grading_configs(is_default)
    ''');

    // Students table with enhanced fields
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        program TEXT NOT NULL,
        program_type TEXT NOT NULL DEFAULT 'bachelors',
        program_duration_years INTEGER NOT NULL DEFAULT 4,
        gpa_scale REAL NOT NULL,
        enrollment_date TEXT NOT NULL,
        start_term TEXT NOT NULL DEFAULT 'fall',
        total_credits_required INTEGER NOT NULL,
        retake_policy TEXT NOT NULL,
        grading_config_id TEXT,
        FOREIGN KEY (grading_config_id) REFERENCES grading_configs(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_students_grading_config ON students(grading_config_id)
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

    // Assessments table
    await db.execute('''
      CREATE TABLE assessments (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        weight REAL NOT NULL,
        total_points REAL NOT NULL,
        earned_points REAL,
        due_date TEXT,
        submitted_date TEXT,
        is_dropped INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_assessments_course ON assessments(course_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_assessments_type ON assessments(type)
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

  /// Handle database upgrades for existing installations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to version 2 (program fields)
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE students ADD COLUMN program_type TEXT NOT NULL DEFAULT 'bachelors'
      ''');

      await db.execute('''
        ALTER TABLE students ADD COLUMN program_duration_years INTEGER NOT NULL DEFAULT 4
      ''');

      await db.execute('''
        ALTER TABLE students ADD COLUMN start_term TEXT NOT NULL DEFAULT 'fall'
      ''');
    }

    // Migration from version 2 to version 3 (grading configs)
    if (oldVersion < 3) {
      // Create grading configurations table
      await db.execute('''
        CREATE TABLE grading_configs (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          system_type TEXT NOT NULL,
          max_gpa REAL NOT NULL,
          min_gpa REAL NOT NULL DEFAULT 0.0,
          grade_to_point_map TEXT NOT NULL,
          classifications TEXT NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          last_modified TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_grading_configs_default 
        ON grading_configs(is_default)
      ''');

      // Add grading_config_id to students table
      await db.execute('''
        ALTER TABLE students 
        ADD COLUMN grading_config_id TEXT
      ''');

      await db.execute('''
        CREATE INDEX idx_students_grading_config ON students(grading_config_id)
      ''');
    }

    // Migration to version 4: assessments table
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE assessments (
          id TEXT PRIMARY KEY,
          course_id TEXT NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          weight REAL NOT NULL,
          total_points REAL NOT NULL,
          earned_points REAL,
          due_date TEXT,
          submitted_date TEXT,
          FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_assessments_course ON assessments(course_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_assessments_type ON assessments(type)
      ''');

      // Seed sample data (demo)
      await db.insert('assessments', {
        'id': 'seed_assessment_1',
        'course_id': 'seed_course_1',
        'name': 'Midterm Exam',
        'type': 'midterm',
        'weight': 30.0,
        'total_points': 100.0,
        'earned_points': 85.0,
        'due_date': DateTime.now().toIso8601String(),
        'submitted_date': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Migration to version 5: dropped-assessment flag
    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE assessments
        ADD COLUMN is_dropped INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (useful for development/testing)
  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'gpa_tracker.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Reset database (drop all tables and recreate)
  Future<void> resetDatabase() async {
    final db = await database;

    // Drop all tables in correct order (respecting foreign keys)
    await db.execute('DROP TABLE IF EXISTS gpa_records');
    await db.execute('DROP TABLE IF EXISTS assessments');
    await db.execute('DROP TABLE IF EXISTS courses');
    await db.execute('DROP TABLE IF EXISTS semesters');
    await db.execute('DROP TABLE IF EXISTS students');
    await db.execute('DROP TABLE IF EXISTS grading_configs');

    // Recreate database
    await _createDatabase(db, 5);
  }

  /// Get all grading configurations
  Future<List<Map<String, dynamic>>> getGradingConfigs() async {
    final db = await database;
    return await db.query(
      'grading_configs',
      orderBy: 'is_default DESC, name ASC',
    );
  }

  /// Get default grading configuration
  Future<Map<String, dynamic>?> getDefaultGradingConfig() async {
    final db = await database;
    final results = await db.query(
      'grading_configs',
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Set a grading config as default (unsets previous default)
  Future<void> setDefaultGradingConfig(String configId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Unset all defaults
      await txn.update(
        'grading_configs',
        {'is_default': 0},
        where: 'is_default = ?',
        whereArgs: [1],
      );

      // Set new default
      await txn.update(
        'grading_configs',
        {'is_default': 1, 'last_modified': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [configId],
      );
    });
  }

  /// Insert grading configuration
  Future<void> insertGradingConfig(Map<String, dynamic> config) async {
    final db = await database;
    await db.insert('grading_configs', config);
  }

  /// Update grading configuration
  Future<void> updateGradingConfig(
    String id,
    Map<String, dynamic> config,
  ) async {
    final db = await database;
    await db.update(
      'grading_configs',
      {...config, 'last_modified': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete grading configuration
  Future<void> deleteGradingConfig(String id) async {
    final db = await database;

    // Check if any students are using this config
    final students = await db.query(
      'students',
      where: 'grading_config_id = ?',
      whereArgs: [id],
    );

    if (students.isNotEmpty) {
      throw Exception(
        'Cannot delete grading config: ${students.length} student(s) are using it',
      );
    }

    await db.delete('grading_configs', where: 'id = ?', whereArgs: [id]);
  }
}
