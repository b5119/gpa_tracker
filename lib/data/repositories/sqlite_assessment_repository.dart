import 'package:sqflite/sqflite.dart';

import '../../domain/entities/assessment.dart';
import '../datasources/local/database_service.dart';

class SQLiteAssessmentRepository {
  final DatabaseService _dbService;

  SQLiteAssessmentRepository(this._dbService);

  Future<List<Assessment>> getAssessmentsByCourse(String courseId) async {
    final db = await _dbService.database;
    final results = await db.query(
      'assessments',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'due_date ASC NULLS LAST',
    );
    return results.map((r) => Assessment.fromJson(r)).toList();
  }

  Future<void> saveAssessment(Assessment assessment) async {
    final db = await _dbService.database;
    await db.insert(
      'assessments',
      assessment.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAssessment(Assessment assessment) async {
    final db = await _dbService.database;
    await db.update(
      'assessments',
      assessment.toJson(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
  }

  Future<void> deleteAssessment(String assessmentId) async {
    final db = await _dbService.database;
    await db.delete('assessments', where: 'id = ?', whereArgs: [assessmentId]);
  }

  /// Batch save/update inside a transaction for efficiency.
  Future<void> upsertBatch(List<Assessment> assessments) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      for (final a in assessments) {
        await txn.insert(
          'assessments',
          a.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
