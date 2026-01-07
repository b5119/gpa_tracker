import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/student.dart';
import '../../domain/models/semester.dart';
import '../../domain/models/course.dart';
import '../../domain/models/gpa_record.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/repositories/academic_repository.dart';
import '../../domain/repositories/gpa_repository.dart';
import '../../domain/services/gpa_calculation_engine.dart';
import '../../domain/services/analytics_engine.dart';
import '../../domain/services/career_intelligence_engine.dart';
import '../../data/datasources/local/database_service.dart';
import '../../data/repositories/sqlite_student_repository.dart';
import '../../data/repositories/sqlite_academic_repository.dart';
import '../../data/repositories/sqlite_gpa_repository.dart';

// Database service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Repository providers
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SQLiteStudentRepository(dbService);
});

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SQLiteAcademicRepository(dbService);
});

final gpaRepositoryProvider = Provider<GPARepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SQLiteGPARepository(dbService);
});

// Domain service providers
final gpaCalculationEngineProvider = Provider<GPACalculationEngine>((ref) {
  return GPACalculationEngine();
});

final analyticsEngineProvider = Provider<GPAAnalyticsEngine>((ref) {
  return GPAAnalyticsEngine();
});

final careerIntelligenceProvider = Provider<CareerIntelligenceEngine>((ref) {
  return CareerIntelligenceEngine.withDefaultSectors();
});

// Student state notifier
class StudentNotifier extends Notifier<AsyncValue<Student?>> {
  late final StudentRepository _repository;
  late final String _studentId;

  @override
  AsyncValue<Student?> build() {
    _repository = ref.watch(studentRepositoryProvider);
    _studentId = ref.watch(currentStudentIdProvider);
    _loadStudent();
    return const AsyncValue.loading();
  }

  Future<void> _loadStudent() async {
    state = const AsyncValue.loading();
    try {
      final student = await _repository.getStudent(_studentId);
      state = AsyncValue.data(student);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateStudent(Student student) async {
    await _repository.updateStudent(student);
    state = AsyncValue.data(student);
  }

  void refresh() => _loadStudent();
}

// Current student ID
final currentStudentIdProvider = StateProvider<String>((ref) => 'default_student');

// Current student
final currentStudentProvider = NotifierProvider<StudentNotifier, AsyncValue<Student?>>(
      () => StudentNotifier(),
);

// Semesters notifier
class SemestersNotifier extends Notifier<AsyncValue<List<Semester>>> {
  late final AcademicRepository _repository;
  late final String _studentId;

  @override
  AsyncValue<List<Semester>> build() {
    _repository = ref.watch(academicRepositoryProvider);
    _studentId = ref.watch(currentStudentIdProvider);
    _loadSemesters();
    return const AsyncValue.loading();
  }

  Future<void> _loadSemesters() async {
    state = const AsyncValue.loading();
    try {
      final semesters = await _repository.getSemestersByStudent(_studentId);
      state = AsyncValue.data(semesters);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addSemester(Semester semester) async {
    await _repository.saveSemester(semester);
    _loadSemesters();
  }

  void refresh() => _loadSemesters();
}

final semestersProvider = NotifierProvider<SemestersNotifier, AsyncValue<List<Semester>>>(
      () => SemestersNotifier(),
);