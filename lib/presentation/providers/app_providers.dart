import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/student.dart';
import '../../domain/models/semester.dart';
import '../../domain/models/course.dart';
import '../../domain/models/gpa_record.dart';
import '../../domain/models/career_sector.dart';
import '../../domain/entities/grading_config.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/repositories/academic_repository.dart';
import '../../domain/repositories/gpa_repository.dart';
import '../../domain/repositories/grading_config_repository.dart';
import '../../domain/usecases/calculate_academic_progress.dart';
import '../../domain/usecases/calculate_semester_gpa.dart';
import '../../domain/usecases/calculate_cumulative_gpa.dart';
import '../../domain/usecases/classify_gpa_standing.dart';
import '../../domain/usecases/analyze_gpa_trend.dart';
import '../../domain/usecases/predict_future_gpa.dart';
import '../../domain/usecases/evaluate_career_readiness.dart';
import '../../domain/usecases/evaluate_academic_eligibility.dart';
import '../../domain/services/gpa_calculation_engine.dart';
import '../../domain/services/analytics_engine.dart';
import '../../domain/services/career_intelligence_engine.dart';
import '../../data/datasources/local/database_service.dart';
import '../../data/repositories/sqlite_student_repository.dart';
import '../../data/repositories/sqlite_academic_repository.dart';
import '../../data/repositories/sqlite_gpa_repository.dart';
import '../../data/repositories/sqlite_grading_config_repository.dart';

// =============================================================================
// INFRASTRUCTURE PROVIDERS
// =============================================================================

/// Database service provider (singleton)
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// =============================================================================
// REPOSITORY PROVIDERS
// =============================================================================

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

final gradingConfigRepositoryProvider = Provider<GradingConfigRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SQLiteGradingConfigRepository(dbService);
});

// =============================================================================
// DOMAIN SERVICE PROVIDERS (Legacy - being replaced by use cases)
// =============================================================================

final gpaCalculationEngineProvider = Provider<GPACalculationEngine>((ref) {
  return GPACalculationEngine();
});

final analyticsEngineProvider = Provider<GPAAnalyticsEngine>((ref) {
  return GPAAnalyticsEngine();
});

final careerIntelligenceProvider = Provider<CareerIntelligenceEngine>((ref) {
  return CareerIntelligenceEngine.withDefaultSectors();
});

// =============================================================================
// USE CASE PROVIDERS
// =============================================================================

final calculateAcademicProgressProvider = Provider<CalculateAcademicProgress>((ref) {
  return CalculateAcademicProgress();
});

final calculateSemesterGPAProvider = Provider<CalculateSemesterGPA>((ref) {
  return CalculateSemesterGPA();
});

final calculateCumulativeGPAProvider = Provider<CalculateCumulativeGPA>((ref) {
  return CalculateCumulativeGPA();
});

final classifyGPAStandingProvider = Provider<ClassifyGPAStanding>((ref) {
  return ClassifyGPAStanding();
});

final analyzeGPATrendProvider = Provider<AnalyzeGPATrend>((ref) {
  return AnalyzeGPATrend();
});

final predictFutureGPAProvider = Provider<PredictFutureGPA>((ref) {
  return PredictFutureGPA();
});

final evaluateCareerReadinessProvider = Provider<EvaluateCareerReadiness>((ref) {
  return EvaluateCareerReadiness();
});

final evaluateAcademicEligibilityProvider = Provider<EvaluateAcademicEligibility>((ref) {
  return EvaluateAcademicEligibility();
});

// =============================================================================
// STATE PROVIDERS
// =============================================================================

/// Current student ID provider
final currentStudentIdProvider = StateProvider<String>((ref) => 'default_student');

// =============================================================================
// GRADING CONFIG NOTIFIER
// =============================================================================

class GradingConfigNotifier extends Notifier<AsyncValue<GradingConfig?>> {
  @override
  AsyncValue<GradingConfig?> build() {
    _loadActiveConfig();
    return const AsyncValue.loading();
  }

  Future<void> _loadActiveConfig() async {
    final repository = ref.read(gradingConfigRepositoryProvider);

    state = const AsyncValue.loading();

    try {
      await repository.initializeDefaults();
      final config = await repository.getActiveConfig();
      state = AsyncValue.data(config);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setActiveConfig(String configId) async {
    final repository = ref.read(gradingConfigRepositoryProvider);

    try {
      await repository.setActiveConfig(configId);
      await _loadActiveConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() => _loadActiveConfig();
}

final gradingConfigProvider = NotifierProvider<GradingConfigNotifier, AsyncValue<GradingConfig?>>(
  GradingConfigNotifier.new,
);

// =============================================================================
// STUDENT NOTIFIER
// =============================================================================

class StudentNotifier extends Notifier<AsyncValue<Student?>> {
  @override
  AsyncValue<Student?> build() {
    _loadStudent();
    return const AsyncValue.loading();
  }

  Future<void> _loadStudent() async {
    final repository = ref.read(studentRepositoryProvider);
    final studentId = ref.read(currentStudentIdProvider);

    state = const AsyncValue.loading();

    try {
      final student = await repository.getStudent(studentId);
      state = AsyncValue.data(student);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateStudent(Student student) async {
    final repository = ref.read(studentRepositoryProvider);

    try {
      await repository.updateStudent(student);
      state = AsyncValue.data(student);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void refresh() => _loadStudent();
}

final currentStudentProvider = NotifierProvider<StudentNotifier, AsyncValue<Student?>>(
  StudentNotifier.new,
);

// =============================================================================
// SEMESTERS NOTIFIER
// =============================================================================

class SemestersNotifier extends Notifier<AsyncValue<List<Semester>>> {
  @override
  AsyncValue<List<Semester>> build() {
    _loadSemesters();
    return const AsyncValue.loading();
  }

  Future<void> _loadSemesters() async {
    final repository = ref.read(academicRepositoryProvider);
    final studentId = ref.read(currentStudentIdProvider);

    state = const AsyncValue.loading();

    try {
      final semesters = await repository.getSemestersByStudent(studentId);
      state = AsyncValue.data(semesters);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addSemester(Semester semester) async {
    final repository = ref.read(academicRepositoryProvider);

    try {
      await repository.saveSemester(semester);
      await _loadSemesters();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateSemester(Semester semester) async {
    final repository = ref.read(academicRepositoryProvider);

    try {
      await repository.updateSemester(semester);
      await _loadSemesters();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteSemester(String semesterId) async {
    final repository = ref.read(academicRepositoryProvider);

    try {
      await repository.deleteSemester(semesterId);
      await _loadSemesters();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void refresh() => _loadSemesters();
}

final semestersProvider = NotifierProvider<SemestersNotifier, AsyncValue<List<Semester>>>(
  SemestersNotifier.new,
);

// =============================================================================
// COMPUTED PROVIDERS (Using Use Cases)
// =============================================================================

/// Current cumulative GPA using Calculate Cumulative GPA use case
final currentGPAProvider = Provider<AsyncValue<double?>>((ref) {
  final semestersAsync = ref.watch(semestersProvider);
  final studentAsync = ref.watch(currentStudentProvider);
  final gradingConfigAsync = ref.watch(gradingConfigProvider);
  final calculateCumulativeGPA = ref.watch(calculateCumulativeGPAProvider);

  return semestersAsync.when(
    data: (semesters) {
      if (semesters.isEmpty) return const AsyncValue.data(null);

      return studentAsync.when(
        data: (student) {
          if (student == null) return const AsyncValue.data(null);

          return gradingConfigAsync.when(
            data: (config) {
              if (config == null) return const AsyncValue.data(null);

              // Convert to use case format
              final semesterCourses = <String, List<Course>>{};
              for (final semester in semesters) {
                semesterCourses[semester.id] = semester.courses;
              }

              final result = calculateCumulativeGPA.execute(
                semesterCourses: semesterCourses,
                retakePolicy: student.retakePolicy,
                gradingConfig: config,
              );

              return AsyncValue.data(result.gpa);
            },
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Academic progress using Calculate Academic Progress use case
final academicProgressProvider = Provider<AsyncValue<AcademicProgress>>((ref) {
  final studentAsync = ref.watch(currentStudentProvider);
  final semestersAsync = ref.watch(semestersProvider);
  final calculateProgress = ref.watch(calculateAcademicProgressProvider);

  return studentAsync.when(
    data: (student) {
      if (student == null) {
        return AsyncValue.error('No student found', StackTrace.current);
      }

      return semestersAsync.when(
        data: (semesters) {
          final completedSemesters = semesters
              .where((s) => s.status == SemesterStatus.completed)
              .toList();

          final earnedCredits = completedSemesters.fold<int>(
            0,
                (sum, s) => sum + s.earnedCredits,
          );

          final progress = calculateProgress.execute(
            student: student,
            completedSemesters: completedSemesters,
            earnedCredits: earnedCredits,
          );

          return AsyncValue.data(progress);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// GPA Standing using Classify GPA Standing use case
final gpaStandingProvider = Provider<AsyncValue<GPAStandingResult>>((ref) {
  final currentGPAAsync = ref.watch(currentGPAProvider);
  final gradingConfigAsync = ref.watch(gradingConfigProvider);
  final classifyStanding = ref.watch(classifyGPAStandingProvider);

  return currentGPAAsync.when(
    data: (gpa) {
      if (gpa == null) {
        return AsyncValue.error('No GPA data', StackTrace.current);
      }

      return gradingConfigAsync.when(
        data: (config) {
          if (config == null) {
            return AsyncValue.error('No grading config', StackTrace.current);
          }

          final standing = classifyStanding.execute(
            gpa: gpa,
            gradingConfig: config,
          );

          return AsyncValue.data(standing);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Trend analysis using Analyze GPA Trend use case
final trendAnalysisProvider = Provider<AsyncValue<TrendAnalysisResult>>((ref) {
  final semestersAsync = ref.watch(semestersProvider);
  final analyzeTrend = ref.watch(analyzeGPATrendProvider);

  return semestersAsync.when(
    data: (semesters) {
      final semesterGPAs = semesters
          .map((s) => s.calculateGPA())
          .where((gpa) => gpa != null)
          .cast<double>()
          .toList();

      final analysis = analyzeTrend.execute(semesterGPAs: semesterGPAs);
      return AsyncValue.data(analysis);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// GPA Prediction using Predict Future GPA use case
final gpaPredictionProvider = Provider<AsyncValue<PredictionResult>>((ref) {
  final semestersAsync = ref.watch(semestersProvider);
  final studentAsync = ref.watch(currentStudentProvider);
  final currentGPAAsync = ref.watch(currentGPAProvider);
  final progressAsync = ref.watch(academicProgressProvider);
  final gradingConfigAsync = ref.watch(gradingConfigProvider);
  final predictFutureGPA = ref.watch(predictFutureGPAProvider);

  return semestersAsync.when(
    data: (semesters) {
      final semesterGPAs = semesters
          .map((s) => s.calculateGPA())
          .where((gpa) => gpa != null)
          .cast<double>()
          .toList();

      return currentGPAAsync.when(
        data: (currentGPA) {
          if (currentGPA == null) {
            return AsyncValue.data(PredictionResult.insufficient());
          }

          return studentAsync.when(
            data: (student) {
              if (student == null) {
                return AsyncValue.data(PredictionResult.insufficient());
              }

              return progressAsync.when(
                data: (progress) {
                  return gradingConfigAsync.when(
                    data: (config) {
                      if (config == null) {
                        return AsyncValue.data(PredictionResult.insufficient());
                      }

                      final prediction = predictFutureGPA.execute(
                        historicalGPAs: semesterGPAs,
                        currentGPA: currentGPA,
                        remainingSemesters: progress.remainingSemesters,
                        currentCredits: progress.earnedCredits,
                        totalCreditsRequired: student.totalCreditsRequired,
                        gradingConfig: config,
                      );

                      return AsyncValue.data(prediction);
                    },
                    loading: () => const AsyncValue.loading(),
                    error: (err, stack) => AsyncValue.error(err, stack),
                  );
                },
                loading: () => const AsyncValue.loading(),
                error: (err, stack) => AsyncValue.error(err, stack),
              );
            },
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Career readiness using Evaluate Career Readiness use case
final careerReadinessProvider = Provider<AsyncValue<CareerReadinessReport>>((ref) {
  final currentGPAAsync = ref.watch(currentGPAProvider);
  final gradingConfigAsync = ref.watch(gradingConfigProvider);
  final evaluateCareerReadiness = ref.watch(evaluateCareerReadinessProvider);

  return currentGPAAsync.when(
    data: (gpa) {
      if (gpa == null) {
        return AsyncValue.error('No GPA data', StackTrace.current);
      }

      return gradingConfigAsync.when(
        data: (config) {
          if (config == null) {
            return AsyncValue.error('No grading config', StackTrace.current);
          }

          // Get sectors from helper function
          final sectors = _getDefaultCareerSectors();

          final report = evaluateCareerReadiness.execute(
            currentGPA: gpa,
            gradingConfig: config,
            sectors: sectors,
          );

          return AsyncValue.data(report);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Academic eligibility using Evaluate Academic Eligibility use case
final academicEligibilityProvider = Provider<AsyncValue<EligibilityReport>>((ref) {
  final studentAsync = ref.watch(currentStudentProvider);
  final currentGPAAsync = ref.watch(currentGPAProvider);
  final progressAsync = ref.watch(academicProgressProvider);
  final gradingConfigAsync = ref.watch(gradingConfigProvider);
  final evaluateEligibility = ref.watch(evaluateAcademicEligibilityProvider);

  return studentAsync.when(
    data: (student) {
      if (student == null) {
        return AsyncValue.error('No student', StackTrace.current);
      }

      return currentGPAAsync.when(
        data: (gpa) {
          if (gpa == null) {
            return AsyncValue.error('No GPA', StackTrace.current);
          }

          return progressAsync.when(
            data: (progress) {
              return gradingConfigAsync.when(
                data: (config) {
                  if (config == null) {
                    return AsyncValue.error('No config', StackTrace.current);
                  }

                  final eligibility = evaluateEligibility.execute(
                    student: student,
                    currentGPA: gpa,
                    earnedCredits: progress.earnedCredits,
                    gradingConfig: config,
                  );

                  return AsyncValue.data(eligibility);
                },
                loading: () => const AsyncValue.loading(),
                error: (err, stack) => AsyncValue.error(err, stack),
              );
            },
            loading: () => const AsyncValue.loading(),
            error: (err, stack) => AsyncValue.error(err, stack),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// =============================================================================
// LEGACY PROVIDERS (For backward compatibility - will be removed)
// =============================================================================

/// Performance analysis provider (Legacy - uses old analytics engine)
final performanceAnalysisProvider = Provider<AsyncValue<PerformanceAnalysis>>((ref) {
  final semestersAsync = ref.watch(semestersProvider);
  final analytics = ref.watch(analyticsEngineProvider);

  return semestersAsync.when(
    data: (semesters) {
      final semesterGPAs = semesters
          .map((s) => s.calculateGPA())
          .where((gpa) => gpa != null)
          .cast<double>()
          .toList();

      final analysis = analytics.analyzePerformance(semesterGPAs);
      return AsyncValue.data(analysis);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Career fit provider (Legacy - uses old career engine)
final careerFitProvider = Provider<AsyncValue<CareerFitReport>>((ref) {
  final currentGPAAsync = ref.watch(currentGPAProvider);
  final careerEngine = ref.watch(careerIntelligenceProvider);

  return currentGPAAsync.when(
    data: (gpa) {
      if (gpa == null) {
        return AsyncValue.error('No GPA data available', StackTrace.current);
      }

      final report = careerEngine.analyzeCareerFit(currentGPA: gpa);
      return AsyncValue.data(report);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/// Get default career sectors
/// TODO: Move to configuration file or database
List<CareerSector> _getDefaultCareerSectors() {
  return [
    const CareerSector(
      id: 'investment-banking',
      name: 'Investment Banking',
      category: 'Finance',
      minimumGPA: 3.2,
      competitiveGPA: 3.7,
      targetGPA: 3.9,
      description: 'Highly selective bulge bracket and boutique investment banks',
      typicalRoles: ['Analyst', 'Associate', 'M&A Specialist'],
      region: 'US',
    ),
    const CareerSector(
      id: 'software-engineering',
      name: 'Software Engineering',
      category: 'Technology',
      minimumGPA: 2.7,
      competitiveGPA: 3.2,
      targetGPA: 3.7,
      description: 'Tech companies (FAANG and startups) - skills matter most',
      typicalRoles: ['Software Engineer', 'Full Stack Developer', 'Backend Engineer'],
      region: 'US',
    ),
    const CareerSector(
      id: 'data-science',
      name: 'Data Science & Analytics',
      category: 'Technology',
      minimumGPA: 3.0,
      competitiveGPA: 3.4,
      targetGPA: 3.7,
      description: 'Analytics and data science roles across industries',
      typicalRoles: ['Data Scientist', 'ML Engineer', 'Analytics Manager'],
      region: 'US',
    ),
    const CareerSector(
      id: 'management-consulting',
      name: 'Management Consulting',
      category: 'Consulting',
      minimumGPA: 3.3,
      competitiveGPA: 3.6,
      targetGPA: 3.8,
      description: 'Top-tier consulting firms (MBB and similar)',
      typicalRoles: ['Analyst', 'Consultant', 'Strategy Associate'],
      region: 'US',
    ),
    const CareerSector(
      id: 'federal-government',
      name: 'Federal Government',
      category: 'Public Sector',
      minimumGPA: 2.5,
      competitiveGPA: 3.0,
      targetGPA: 3.5,
      description: 'Federal agencies and civil service positions',
      typicalRoles: ['Policy Analyst', 'Program Manager', 'Research Specialist'],
      region: 'US',
    ),
  ];
}