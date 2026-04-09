import 'package:sqflite/sqflite.dart';

import '../../domain/entities/assessment.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../datasources/local/database_service.dart';

class SQLiteAssessmentRepository implements AssessmentRepository {
  final DatabaseService _dbService;

  SQLiteAssessmentRepository(this._dbService);

  @override
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

  @override
  Future<void> saveAssessment(Assessment assessment) async {
    final db = await _dbService.database;
    await db.insert(
      'assessments',
      assessment.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateAssessment(Assessment assessment) async {
    final db = await _dbService.database;
    await db.update(
      'assessments',
      assessment.toJson(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
  }

  @override
  Future<void> deleteAssessment(String assessmentId) async {
    final db = await _dbService.database;
    await db.delete('assessments', where: 'id = ?', whereArgs: [assessmentId]);
  }

  /// Batch save/update inside a transaction for efficiency.
  @override
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
