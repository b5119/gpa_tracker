import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/student.dart';
import '../../domain/models/semester.dart';
import '../../domain/models/course.dart';
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
import '../../domain/usecases/calculate_course_gpa_from_assessments.dart';
import '../../domain/services/gpa_calculation_engine.dart';
import '../../domain/services/analytics_engine.dart';
import '../../domain/services/career_intelligence_engine.dart';
import '../../data/datasources/local/database_service.dart';
import '../../data/repositories/sqlite_student_repository.dart';
import '../../data/repositories/sqlite_academic_repository.dart';
import '../../data/repositories/sqlite_gpa_repository.dart';
import '../../data/repositories/sqlite_grading_config_repository.dart';
import '../../data/repositories/sqlite_assessment_repository.dart';
import '../../domain/entities/assessment.dart';
import '../../domain/entities/grading_schema.dart';
import '../../domain/repositories/assessment_repository.dart';

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

final gradingConfigRepositoryProvider = Provider<GradingConfigRepository>((
  ref,
) {
  final dbService = ref.watch(databaseServiceProvider);
  return SQLiteGradingConfigRepository(dbService);
});

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SQLiteAssessmentRepository(dbService);
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

final calculateAcademicProgressProvider = Provider<CalculateAcademicProgress>((
  ref,
) {
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

final evaluateCareerReadinessProvider = Provider<EvaluateCareerReadiness>((
  ref,
) {
  return EvaluateCareerReadiness();
});

final evaluateAcademicEligibilityProvider =
    Provider<EvaluateAcademicEligibility>((ref) {
      return EvaluateAcademicEligibility();
    });

final calculateCourseGPAFromAssessmentsProvider =
    Provider<CalculateCourseGPAFromAssessments>((ref) {
      return CalculateCourseGPAFromAssessments();
    });

// =============================================================================
// STATE PROVIDERS
// =============================================================================

/// Current student ID provider
final currentStudentIdProvider = StateProvider<String>(
  (ref) => DatabaseConstants.defaultStudentId,
);

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
      await _syncStudentScale(config);
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

  Future<void> saveConfig(
    GradingConfig config, {
    bool setActive = false,
  }) async {
    final repository = ref.read(gradingConfigRepositoryProvider);

    try {
      await repository.saveConfig(config);
      if (setActive) {
        await repository.setActiveConfig(config.id);
      }
      await _loadActiveConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteConfig(String configId) async {
    final repository = ref.read(gradingConfigRepositoryProvider);

    try {
      await repository.deleteConfig(configId);
      await _loadActiveConfig();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _syncStudentScale(GradingConfig? config) async {
    final studentState = ref.read(currentStudentProvider);
    final student = studentState.asData?.value;

    if (config == null ||
        student == null ||
        student.gpaScale == config.maxGPA) {
      return;
    }

    try {
      await ref
          .read(currentStudentProvider.notifier)
          .updateStudent(student.copyWith(gpaScale: config.maxGPA));
    } catch (_) {
      // Leave the active grading config intact even if syncing the legacy scale fails.
    }
  }

  void refresh() => _loadActiveConfig();
}

final gradingConfigProvider =
    NotifierProvider<GradingConfigNotifier, AsyncValue<GradingConfig?>>(
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
      var student = await repository.getStudent(studentId);
      if (student == null) {
        student = _buildDefaultStudent(studentId);
        await repository.saveStudent(student);
      }
      state = AsyncValue.data(student);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Student _buildDefaultStudent(String studentId) {
    final now = DateTime.now();
    final startTerm = switch (now.month) {
      >= 8 && <= 12 => AcademicTerm.fall,
      >= 1 && <= 5 => AcademicTerm.spring,
      _ => AcademicTerm.summer,
    };

    return Student(
      id: studentId,
      name: 'Student Profile',
      email: 'student@example.com',
      program: 'Undeclared Program',
      programType: ProgramType.bachelors,
      programDurationYears: 4,
      enrollmentDate: now,
      startTerm: startTerm,
      gpaScale: GPAScales.scale4Point0,
      totalCreditsRequired: AcademicConstants.typicalBachelorsDegreeCredits,
      retakePolicy: RetakePolicy.replace,
    );
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

class AssessmentsNotifier extends Notifier<AsyncValue<List<Assessment>>> {
  AssessmentsNotifier(this.courseId);

  final String courseId;
  late final AssessmentRepository _repository;

  @override
  AsyncValue<List<Assessment>> build() {
    _repository = ref.read(assessmentRepositoryProvider);
    _loadAssessments();
    return const AsyncValue.loading();
  }

  Future<void> _loadAssessments() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAssessmentsByCourse(courseId);
      state = AsyncValue.data(items);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> loadAssessmentsByCourse(String targetCourseId) async {
    if (targetCourseId != courseId) return;
    await _loadAssessments();
  }

  Future<void> addAssessment(Assessment assessment) async {
    try {
      await _repository.saveAssessment(assessment);
      final current = state.maybeWhen(
        data: (items) => items,
        orElse: () => const <Assessment>[],
      );
      state = AsyncValue.data([...current, assessment]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> updateAssessment(Assessment assessment) async {
    try {
      await _repository.updateAssessment(assessment);
      final current = state.maybeWhen(
        data: (items) => items,
        orElse: () => const <Assessment>[],
      );
      state = AsyncValue.data(
        current.map((a) => a.id == assessment.id ? assessment : a).toList(),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _repository.deleteAssessment(assessmentId);
      final current = state.maybeWhen(
        data: (items) => items,
        orElse: () => const <Assessment>[],
      );
      state = AsyncValue.data(
        current.where((a) => a.id != assessmentId).toList(),
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

final assessmentsProvider =
    NotifierProvider.family<
      AssessmentsNotifier,
      AsyncValue<List<Assessment>>,
      String
    >((courseId) => AssessmentsNotifier(courseId));

final courseGPAProvider = Provider.family<AsyncValue<CourseGPAResult>, String>((
  ref,
  courseId,
) {
  final assessmentsAsync = ref.watch(assessmentsProvider(courseId));
  final gradingConfigAsync = ref.watch(gradingConfigProvider);
  final calculateUseCase = ref.watch(calculateCourseGPAFromAssessmentsProvider);

  return assessmentsAsync.when(
    data: (assessments) {
      return gradingConfigAsync.when(
        data: (config) {
          if (config == null) {
            return AsyncValue.error('No grading config', StackTrace.current);
          }

          // TODO: derive schema from config; placeholder uses percentage bands.
          final schema = GradingSchema(
            id: 'default',
            name: 'Default 4.0',
            mode: GradingMode.percentage,
            maxGpa: 4.0,
            percentageBands: {90: 4.0, 80: 3.0, 70: 2.0, 60: 1.0, 0: 0.0},
          );
          final result = calculateUseCase.execute(
            assessments: assessments,
            gradingSchema: schema,
          );
          return AsyncValue.data(result);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

final currentStudentProvider =
    NotifierProvider<StudentNotifier, AsyncValue<Student?>>(
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

final semestersProvider =
    NotifierProvider<SemestersNotifier, AsyncValue<List<Semester>>>(
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
final careerReadinessProvider = Provider<AsyncValue<CareerReadinessReport>>((
  ref,
) {
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
final academicEligibilityProvider = Provider<AsyncValue<EligibilityReport>>((
  ref,
) {
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
final performanceAnalysisProvider = Provider<AsyncValue<PerformanceAnalysis>>((
  ref,
) {
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
      description:
          'Highly selective bulge bracket and boutique investment banks',
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
      typicalRoles: [
        'Software Engineer',
        'Full Stack Developer',
        'Backend Engineer',
      ],
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
      typicalRoles: [
        'Policy Analyst',
        'Program Manager',
        'Research Specialist',
      ],
      region: 'US',
    ),
  ];
}
