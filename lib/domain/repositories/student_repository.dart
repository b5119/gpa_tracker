import '../models/student.dart';

abstract class StudentRepository {
  Future<Student?> getStudent(String id);
  Future<void> saveStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String id);
}
