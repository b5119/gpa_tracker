// =============================================================================
// DOMAIN MODELS - CLEAN ARCHITECTURE DOMAIN LAYER
// =============================================================================
// These models represent pure business entities with no framework dependencies.
// They are immutable, serializable, and contain domain validation logic.

import 'package:equatable/equatable.dart';

// =============================================================================
// STUDENT MODEL
// =============================================================================
/// Represents a student entity with academic profile information.
///
/// This is the root aggregate in our domain model. A student owns multiple
/// semesters, and through them, multiple courses. The student model maintains
/// GPA scale configuration which affects all GPA calculations.
class Student extends Equatable {
  final String id;
  final String name;
  final String email;
  final String program; // e.g., "Computer Science"
  final double gpaScale; // 4.0 or 5.0 scale
  final DateTime enrollmentDate;
  final int totalCreditsRequired; // For degree completion
  final RetakePolicy retakePolicy;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.program,
    this.gpaScale = 4.0,
    required this.enrollmentDate,
    required this.totalCreditsRequired,
    this.retakePolicy = RetakePolicy.replace,
  });

  /// Creates Student from JSON (for persistence layer)
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      program: json['program'] as String,
      gpaScale: (json['gpaScale'] as num).toDouble(),
      enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
      totalCreditsRequired: json['totalCreditsRequired'] as int,
      retakePolicy: RetakePolicy.values.firstWhere(
            (e) => e.toString() == json['retakePolicy'],
        orElse: () => RetakePolicy.replace,
      ),
    );
  }

  /// Converts Student to JSON (for persistence layer)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'program': program,
      'gpaScale': gpaScale,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'totalCreditsRequired': totalCreditsRequired,
      'retakePolicy': retakePolicy.toString(),
    };
  }

  /// Creates a copy with modified fields (immutability pattern)
  Student copyWith({
    String? name,
    String? email,
    String? program,
    double? gpaScale,
    DateTime? enrollmentDate,
    int? totalCreditsRequired,
    RetakePolicy? retakePolicy,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      program: program ?? this.program,
      gpaScale: gpaScale ?? this.gpaScale,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      totalCreditsRequired: totalCreditsRequired ?? this.totalCreditsRequired,
      retakePolicy: retakePolicy ?? this.retakePolicy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    program,
    gpaScale,
    enrollmentDate,
    totalCreditsRequired,
    retakePolicy,
  ];
}

/// Defines how course retakes are handled in GPA calculations.
///
/// REPLACE: Only the most recent grade counts (most common policy)
/// AVERAGE: All attempt grades are averaged
/// BEST: Highest grade across attempts counts
enum RetakePolicy {
  replace, // Most recent grade replaces older grades
  average, // All attempts are averaged
  best, // Best grade across all attempts
}

// =============================================================================
// SEMESTER MODEL
// =============================================================================
/// Represents an academic semester/term.
///
/// Semesters are time-bounded collections of courses. They maintain their own
/// GPA calculation and serve as the unit of academic progress tracking.
class Semester extends Equatable {
  final String id;
  final String studentId; // Foreign key to Student
  final String name; // e.g., "Fall 2024"
  final DateTime startDate;
  final DateTime endDate;
  final SemesterStatus status;
  final List<Course> courses;

  const Semester({
    required this.id,
    required this.studentId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.courses = const [],
  });

  /// Calculates semester GPA using credit-weighted formula.
  ///
  /// Formula: Σ(grade_point × credits) / Σ(credits)
  /// Only includes courses with grades (excludes in-progress)
  /// Returns null if no graded courses exist
  double? calculateGPA() {
    final gradedCourses = courses.where((c) => c.gradePoint != null).toList();

    if (gradedCourses.isEmpty) return null;

    double totalQualityPoints = 0.0;
    int totalCredits = 0;

    for (final course in gradedCourses) {
      totalQualityPoints += course.gradePoint! * course.credits;
      totalCredits += course.credits;
    }

    return totalCredits > 0 ? totalQualityPoints / totalCredits : null;
  }

  /// Total credits attempted in this semester
  int get totalCredits => courses.fold(0, (sum, c) => sum + c.credits);

  /// Total credits earned (passed courses only)
  int get earnedCredits => courses
      .where((c) => c.isPassing)
      .fold(0, (sum, c) => sum + c.credits);

  /// Percentage of courses completed
  double get completionRate {
    final total = courses.length;
    if (total == 0) return 0.0;
    final completed = courses.where((c) => c.gradePoint != null).length;
    return completed / total;
  }

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: SemesterStatus.values.firstWhere(
            (e) => e.toString() == json['status'],
      ),
      courses: (json['courses'] as List<dynamic>?)
          ?.map((c) => Course.fromJson(c as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.toString(),
      'courses': courses.map((c) => c.toJson()).toList(),
    };
  }

  Semester copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    SemesterStatus? status,
    List<Course>? courses,
  }) {
    return Semester(
      id: id,
      studentId: studentId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      courses: courses ?? this.courses,
    );
  }

  @override
  List<Object?> get props => [id, studentId, name, startDate, endDate, status, courses];
}

enum SemesterStatus {
  upcoming, // Not yet started
  inProgress, // Currently active
  completed, // Finished with all grades
}

// =============================================================================
// COURSE MODEL
// =============================================================================
/// Represents an individual course within a semester.
///
/// Courses are the atomic unit of academic work. Each course has credits,
/// a grade, and metadata. Multiple attempts of the same course are tracked
/// via the attemptNumber field.
class Course extends Equatable {
  final String id;
  final String semesterId; // Foreign key to Semester
  final String courseCode; // e.g., "CS101"
  final String courseName; // e.g., "Introduction to Programming"
  final int credits; // Credit hours (typically 1-4)
  final String? letterGrade; // "A", "B+", "C", etc. (null if in progress)
  final double? gradePoint; // Numeric grade on GPA scale (null if in progress)
  final int attemptNumber; // 1 for first attempt, 2 for retake, etc.
  final CourseType courseType;

  const Course({
    required this.id,
    required this.semesterId,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    this.letterGrade,
    this.gradePoint,
    this.attemptNumber = 1,
    this.courseType = CourseType.major,
  });

  /// Whether this course was passed (typically >= 2.0 on 4.0 scale)
  bool get isPassing => gradePoint != null && gradePoint! >= 2.0;

  /// Whether this course has been graded
  bool get isGraded => gradePoint != null;

  /// Quality points earned (grade × credits)
  double get qualityPoints => (gradePoint ?? 0.0) * credits;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      semesterId: json['semesterId'] as String,
      courseCode: json['courseCode'] as String,
      courseName: json['courseName'] as String,
      credits: json['credits'] as int,
      letterGrade: json['letterGrade'] as String?,
      gradePoint: (json['gradePoint'] as num?)?.toDouble(),
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      courseType: CourseType.values.firstWhere(
            (e) => e.toString() == json['courseType'],
        orElse: () => CourseType.major,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semesterId': semesterId,
      'courseCode': courseCode,
      'courseName': courseName,
      'credits': credits,
      'letterGrade': letterGrade,
      'gradePoint': gradePoint,
      'attemptNumber': attemptNumber,
      'courseType': courseType.toString(),
    };
  }

  Course copyWith({
    String? courseCode,
    String? courseName,
    int? credits,
    String? letterGrade,
    double? gradePoint,
    int? attemptNumber,
    CourseType? courseType,
  }) {
    return Course(
      id: id,
      semesterId: semesterId,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      credits: credits ?? this.credits,
      letterGrade: letterGrade ?? this.letterGrade,
      gradePoint: gradePoint ?? this.gradePoint,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      courseType: courseType ?? this.courseType,
    );
  }

  @override
  List<Object?> get props => [
    id,
    semesterId,
    courseCode,
    courseName,
    credits,
    letterGrade,
    gradePoint,
    attemptNumber,
    courseType,
  ];
}

enum CourseType {
  major, // Core major requirement
  minor, // Minor requirement
  elective, // Free elective
  general, // General education
}

// =============================================================================
// GPA RECORD MODEL
// =============================================================================
/// Represents a calculated GPA at a specific point in time.
///
/// This is a value object that captures the result of GPA calculations.
/// It includes cumulative GPA, semester GPA, and metadata about the calculation.
class GPARecord extends Equatable {
  final String studentId;
  final DateTime calculatedAt;
  final double cumulativeGPA; // Overall GPA across all semesters
  final double? semesterGPA; // GPA for specific semester (if applicable)
  final int totalCreditsAttempted;
  final int totalCreditsEarned;
  final double totalQualityPoints;
  final String? semesterId; // If this is semester-specific GPA

  const GPARecord({
    required this.studentId,
    required this.calculatedAt,
    required this.cumulativeGPA,
    this.semesterGPA,
    required this.totalCreditsAttempted,
    required this.totalCreditsEarned,
    required this.totalQualityPoints,
    this.semesterId,
  });

  /// Academic standing classification based on GPA
  AcademicStanding get academicStanding {
    if (cumulativeGPA >= 3.5) return AcademicStanding.deansList;
    if (cumulativeGPA >= 3.0) return AcademicStanding.goodStanding;
    if (cumulativeGPA >= 2.0) return AcademicStanding.satisfactory;
    if (cumulativeGPA >= 1.0) return AcademicStanding.probation;
    return AcademicStanding.academicDismissal;
  }

  factory GPARecord.fromJson(Map<String, dynamic> json) {
    return GPARecord(
      studentId: json['studentId'] as String,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      cumulativeGPA: (json['cumulativeGPA'] as num).toDouble(),
      semesterGPA: (json['semesterGPA'] as num?)?.toDouble(),
      totalCreditsAttempted: json['totalCreditsAttempted'] as int,
      totalCreditsEarned: json['totalCreditsEarned'] as int,
      totalQualityPoints: (json['totalQualityPoints'] as num).toDouble(),
      semesterId: json['semesterId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'calculatedAt': calculatedAt.toIso8601String(),
      'cumulativeGPA': cumulativeGPA,
      'semesterGPA': semesterGPA,
      'totalCreditsAttempted': totalCreditsAttempted,
      'totalCreditsEarned': totalCreditsEarned,
      'totalQualityPoints': totalQualityPoints,
      'semesterId': semesterId,
    };
  }

  @override
  List<Object?> get props => [
    studentId,
    calculatedAt,
    cumulativeGPA,
    semesterGPA,
    totalCreditsAttempted,
    totalCreditsEarned,
    totalQualityPoints,
    semesterId,
  ];
}

enum AcademicStanding {
  deansList, // GPA >= 3.5
  goodStanding, // GPA >= 3.0
  satisfactory, // GPA >= 2.0
  probation, // GPA >= 1.0
  academicDismissal, // GPA < 1.0
}

// =============================================================================
// CAREER SECTOR MODEL
// =============================================================================
/// Represents an employment sector with GPA requirements.
///
/// Different industries have different GPA expectations. This model captures
/// minimum viable GPAs and competitive thresholds for various career paths.
class CareerSector extends Equatable {
  final String id;
  final String name; // e.g., "Investment Banking"
  final String category; // e.g., "Finance"
  final double minimumGPA; // Absolute minimum to be considered
  final double competitiveGPA; // GPA needed to be competitive
  final double targetGPA; // Ideal GPA for top opportunities
  final String description;
  final List<String> typicalRoles; // Common job titles in this sector
  final String region; // "US", "EU", "Global", etc.

  const CareerSector({
    required this.id,
    required this.name,
    required this.category,
    required this.minimumGPA,
    required this.competitiveGPA,
    required this.targetGPA,
    required this.description,
    required this.typicalRoles,
    this.region = 'Global',
  });

  /// Calculates fitness score (0.0 to 1.0) for a given GPA
  ///
  /// Returns:
  /// - 0.0 if below minimum
  /// - 0.0-0.5 between minimum and competitive
  /// - 0.5-1.0 between competitive and target
  /// - 1.0 if at or above target
  double calculateFitScore(double currentGPA) {
    if (currentGPA < minimumGPA) return 0.0;
    if (currentGPA >= targetGPA) return 1.0;

    if (currentGPA < competitiveGPA) {
      // Scale 0.0 to 0.5 between minimum and competitive
      return 0.5 * (currentGPA - minimumGPA) / (competitiveGPA - minimumGPA);
    } else {
      // Scale 0.5 to 1.0 between competitive and target
      return 0.5 + 0.5 * (currentGPA - competitiveGPA) / (targetGPA - competitiveGPA);
    }
  }

  /// Determines readiness level for this sector
  CareerReadiness getReadiness(double currentGPA) {
    if (currentGPA < minimumGPA) return CareerReadiness.notReady;
    if (currentGPA < competitiveGPA) return CareerReadiness.eligible;
    if (currentGPA < targetGPA) return CareerReadiness.competitive;
    return CareerReadiness.highlyCompetitive;
  }

  factory CareerSector.fromJson(Map<String, dynamic> json) {
    return CareerSector(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      minimumGPA: (json['minimumGPA'] as num).toDouble(),
      competitiveGPA: (json['competitiveGPA'] as num).toDouble(),
      targetGPA: (json['targetGPA'] as num).toDouble(),
      description: json['description'] as String,
      typicalRoles: List<String>.from(json['typicalRoles'] as List),
      region: json['region'] as String? ?? 'Global',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'minimumGPA': minimumGPA,
      'competitiveGPA': competitiveGPA,
      'targetGPA': targetGPA,
      'description': description,
      'typicalRoles': typicalRoles,
      'region': region,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    minimumGPA,
    competitiveGPA,
    targetGPA,
    description,
    typicalRoles,
    region,
  ];
}

enum CareerReadiness {
  notReady, // Below minimum GPA
  eligible, // Meets minimum but not competitive
  competitive, // Meets competitive threshold
  highlyCompetitive, // Meets or exceeds target GPA
}

// =============================================================================
// GPA PROJECTION MODEL
// =============================================================================
/// Represents a predicted future GPA scenario.
///
/// This value object encapsulates the results of predictive modeling,
/// including best/worst case scenarios and confidence metrics.
class GPAProjection extends Equatable {
  final String studentId;
  final DateTime projectedDate; // When this GPA is expected to be achieved
  final double predictedGPA; // Most likely GPA outcome
  final double bestCaseGPA; // Optimistic scenario
  final double worstCaseGPA; // Pessimistic scenario
  final double confidenceScore; // 0.0 to 1.0 (1.0 = highly confident)
  final int remainingCredits; // Credits left to complete
  final String methodology; // "linear_regression", "monte_carlo", etc.
  final Map<String, dynamic> metadata; // Additional context

  const GPAProjection({
    required this.studentId,
    required this.projectedDate,
    required this.predictedGPA,
    required this.bestCaseGPA,
    required this.worstCaseGPA,
    required this.confidenceScore,
    required this.remainingCredits,
    required this.methodology,
    this.metadata = const {},
  });

  /// Range of possible outcomes (best - worst)
  double get projectionRange => bestCaseGPA - worstCaseGPA;

  /// Whether this projection is reliable enough to act on
  bool get isReliable => confidenceScore >= 0.6 && projectionRange <= 0.5;

  factory GPAProjection.fromJson(Map<String, dynamic> json) {
    return GPAProjection(
      studentId: json['studentId'] as String,
      projectedDate: DateTime.parse(json['projectedDate'] as String),
      predictedGPA: (json['predictedGPA'] as num).toDouble(),
      bestCaseGPA: (json['bestCaseGPA'] as num).toDouble(),
      worstCaseGPA: (json['worstCaseGPA'] as num).toDouble(),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      remainingCredits: json['remainingCredits'] as int,
      methodology: json['methodology'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'projectedDate': projectedDate.toIso8601String(),
      'predictedGPA': predictedGPA,
      'bestCaseGPA': bestCaseGPA,
      'worstCaseGPA': worstCaseGPA,
      'confidenceScore': confidenceScore,
      'remainingCredits': remainingCredits,
      'methodology': methodology,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    studentId,
    projectedDate,
    predictedGPA,
    bestCaseGPA,
    worstCaseGPA,
    confidenceScore,
    remainingCredits,
    methodology,
    metadata,
  ];
}