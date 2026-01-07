import '../models/semester.dart';
import '../models/course.dart';

abstract class AcademicRepository {
  Future<List<Semester>> getSemestersByStudent(String studentId);
  Future<Semester?> getSemester(String id);
  Future<void> saveSemester(Semester semester);
  Future<void> updateSemester(Semester semester);
  Future<void> deleteSemester(String id);

  Future<List<Course>> getCoursesBySemester(String semesterId);
  Future<void> saveCourse(Course course);
  Future<void> updateCourse(Course course);
  Future<void> deleteCourse(String id);
}