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
      orderBy: 'CASE WHEN due_date IS NULL THEN 1 ELSE 0 END, due_date ASC',
    );
    return results.map((r) => Assessment.fromJson(r)).toList();
  }

  @override
  Future<void> saveAssessment(Assessment assessment) async {
    final db = await _dbService.database;
    await db.insert(
      'assessments',
      _toDatabaseRow(assessment),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateAssessment(Assessment assessment) async {
    final db = await _dbService.database;
    await db.update(
      'assessments',
      _toDatabaseRow(assessment),
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
          _toDatabaseRow(a),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Map<String, dynamic> _toDatabaseRow(Assessment assessment) {
    return {
      'id': assessment.id,
      'course_id': assessment.courseId,
      'name': assessment.name,
      'type': assessment.type.name,
      'weight': assessment.weightPercent,
      'total_points': assessment.totalPoints,
      'earned_points': assessment.pointsEarned,
      'due_date': assessment.dueDate?.toIso8601String(),
      'submitted_date': assessment.submittedDate?.toIso8601String(),
      'is_dropped': assessment.isDropped ? 1 : 0,
    };
  }
}
