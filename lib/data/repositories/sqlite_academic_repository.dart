import 'package:sqflite/sqflite.dart';
import '../../../domain/repositories/academic_repository.dart';
import '../../../domain/models/semester.dart';
import '../../../domain/models/course.dart';
import '../datasources/local/database_service.dart';
class SQLiteAcademicRepository implements AcademicRepository {
  final DatabaseService _dbService;

  SQLiteAcademicRepository(this._dbService);

  @override
  Future<List<Semester>> getSemestersByStudent(String studentId) async {
    final db = await _dbService.database;
    final results = await db.query(
      'semesters',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'start_date ASC',
    );

    // Load courses for each semester
    final semesters = <Semester>[];
    for (final result in results) {
      final semester = Semester.fromJson(result);
      final courses = await getCoursesBySemester(semester.id);
      semesters.add(semester.copyWith(courses: courses));
    }

    return semesters;
  }

  @override
  Future<Semester?> getSemester(String id) async {
    final db = await _dbService.database;
    final results = await db.query(
      'semesters',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final semester = Semester.fromJson(results.first);
    final courses = await getCoursesBySemester(id);

    return semester.copyWith(courses: courses);
  }

  @override
  Future<void> saveSemester(Semester semester) async {
    final db = await _dbService.database;

    // Save semester without courses
    final semesterData = semester.toJson();
    semesterData.remove('courses'); // Don't save courses in semester table

    await db.insert(
      'semesters',
      semesterData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save courses separately
    for (final course in semester.courses) {
      await saveCourse(course);
    }
  }

  @override
  Future<void> updateSemester(Semester semester) async {
    final db = await _dbService.database;

    final semesterData = semester.toJson();
    semesterData.remove('courses');

    await db.update(
      'semesters',
      semesterData,
      where: 'id = ?',
      whereArgs: [semester.id],
    );

    // Update courses
    for (final course in semester.courses) {
      await updateCourse(course);
    }
  }

  @override
  Future<void> deleteSemester(String id) async {
    final db = await _dbService.database;
    await db.delete(
      'semesters',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Courses cascade delete automatically
  }

  @override
  Future<List<Course>> getCoursesBySemester(String semesterId) async {
    final db = await _dbService.database;
    final results = await db.query(
      'courses',
      where: 'semester_id = ?',
      whereArgs: [semesterId],
    );

    return results.map((r) => Course.fromJson(r)).toList();
  }

  @override
  Future<void> saveCourse(Course course) async {
    final db = await _dbService.database;
    await db.insert(
      'courses',
      course.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCourse(Course course) async {
    final db = await _dbService.database;
    await db.update(
      'courses',
      course.toJson(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  @override
  Future<void> deleteCourse(String id) async {
    final db = await _dbService.database;
    await db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}