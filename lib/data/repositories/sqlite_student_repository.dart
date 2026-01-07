// =============================================================================
// SQLITE REPOSITORY IMPLEMENTATIONS
// =============================================================================
import 'package:sqflite/sqflite.dart';
import '../../../domain/repositories/student_repository.dart';
import '../../../domain/models/student.dart';
import '../datasources/local/database_service.dart';
class SQLiteStudentRepository implements StudentRepository {
  final DatabaseService _dbService;

  SQLiteStudentRepository(this._dbService);

  @override
  Future<Student?> getStudent(String id) async {
    final db = await _dbService.database;
    final results = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Student.fromJson(results.first);
  }

  @override
  Future<void> saveStudent(Student student) async {
    final db = await _dbService.database;
    await db.insert(
      'students',
      student.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateStudent(Student student) async {
    final db = await _dbService.database;
    await db.update(
      'students',
      student.toJson(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  @override
  Future<void> deleteStudent(String id) async {
    final db = await _dbService.database;
    await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
