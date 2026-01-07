import 'package:sqflite/sqflite.dart';
import '../../../domain/repositories/gpa_repository.dart';
import '../../../domain/models/gpa_record.dart';

import '../datasources/local/database_service.dart';
class SQLiteGPARepository implements GPARepository {
  final DatabaseService _dbService;

  SQLiteGPARepository(this._dbService);

  @override
  Future<List<GPARecord>> getGPAHistory(String studentId) async {
    final db = await _dbService.database;
    final results = await db.query(
      'gpa_records',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'calculated_at ASC',
    );

    return results.map((r) => GPARecord.fromJson(r)).toList();
  }

  @override
  Future<void> saveGPARecord(GPARecord record) async {
    final db = await _dbService.database;
    await db.insert(
      'gpa_records',
      record.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<GPARecord?> getLatestGPA(String studentId) async {
    final db = await _dbService.database;
    final results = await db.query(
      'gpa_records',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'calculated_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return GPARecord.fromJson(results.first);
  }
}