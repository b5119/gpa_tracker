import 'package:equatable/equatable.dart';

/// Represents a student's complete academic identity and program context.
///
/// WHY THIS MATTERS:
/// Academic performance cannot be interpreted without program context.
/// A 3.2 GPA means different things in:
/// - Year 1 vs Year 4
/// - Bachelor's vs Master's
/// - 3-year vs 4-year program
///
/// Time-indexed modeling enables:
/// - Accurate progress tracking
/// - Realistic forecasting
/// - Context-aware eligibility checks
class Student extends Equatable {
  final String id;
  final String name;
  final String email;

  // Program Identity
  final String program; // e.g., "Computer Science"
  final ProgramType programType; // Degree classification
  final int programDurationYears; // Total program length

  // Temporal Context
  final DateTime enrollmentDate; // When student started
  final AcademicTerm startTerm; // Which semester they started in

  // Academic Configuration
  final double gpaScale; // 4.0 or 5.0 (will be migrated to GradingConfig)
  final int totalCreditsRequired;
  final RetakePolicy retakePolicy;

  // Computed Fields (not stored, derived on-demand)
  /// Current academic year (1-based: 1, 2, 3, 4)
  int get currentYear {
    final now = DateTime.now();
    final yearsSinceEnrollment = now.difference(enrollmentDate).inDays ~/ 365;
    return (yearsSinceEnrollment + 1).clamp(1, programDurationYears);
  }

  /// Current semester within the academic year
  AcademicTerm get currentTerm {
    final now = DateTime.now();
    final month = now.month;

    // Standard academic calendar (customizable in future)
    if (month >= 8 && month <= 12) return AcademicTerm.fall;
    if (month >= 1 && month <= 5) return AcademicTerm.spring;
    return AcademicTerm.summer;
  }

  /// Total semesters since enrollment
  int get semestersSinceEnrollment {
    final now = DateTime.now();
    final monthsSinceEnrollment = now.difference(enrollmentDate).inDays ~/ 30;

    // Approximate: 2 major semesters per year (Fall/Spring)
    return (monthsSinceEnrollment / 6).floor();
  }

  /// Expected graduation date
  DateTime get expectedGraduationDate {
    return DateTime(
      enrollmentDate.year + programDurationYears,
      enrollmentDate.month,
      enrollmentDate.day,
    );
  }

  /// Is student on track for on-time graduation?
  bool isOnPace(int completedCredits) {
    final expectedCredits =
        (totalCreditsRequired *
                (semestersSinceEnrollment / (programDurationYears * 2)))
            .round();
    return completedCredits >= (expectedCredits * 0.9); // 10% tolerance
  }

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.program,
    required this.programType,
    required this.programDurationYears,
    required this.enrollmentDate,
    required this.startTerm,
    this.gpaScale = 4.0,
    required this.totalCreditsRequired,
    this.retakePolicy = RetakePolicy.replace,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      program: json['program'] as String,
      programType: ProgramType.values.firstWhere(
        (e) => e.toString() == 'ProgramType.${json['program_type']}',
        orElse: () => ProgramType.bachelors,
      ),
      programDurationYears: json['program_duration_years'] as int? ?? 4,
      enrollmentDate: DateTime.parse(json['enrollment_date'] as String),
      startTerm: AcademicTerm.values.firstWhere(
        (e) => e.toString() == 'AcademicTerm.${json['start_term']}',
        orElse: () => AcademicTerm.fall,
      ),
      gpaScale: (json['gpa_scale'] as num).toDouble(),
      totalCreditsRequired: json['total_credits_required'] as int,
      retakePolicy: RetakePolicy.values.firstWhere(
        (e) => e.toString() == 'RetakePolicy.${json['retake_policy']}',
        orElse: () => RetakePolicy.replace,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'program': program,
      'program_type': programType.name,
      'program_duration_years': programDurationYears,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'start_term': startTerm.name,
      'gpa_scale': gpaScale,
      'total_credits_required': totalCreditsRequired,
      'retake_policy': retakePolicy.name,
    };
  }

  Student copyWith({
    String? name,
    String? email,
    String? program,
    ProgramType? programType,
    int? programDurationYears,
    DateTime? enrollmentDate,
    AcademicTerm? startTerm,
    double? gpaScale,
    int? totalCreditsRequired,
    RetakePolicy? retakePolicy,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      program: program ?? this.program,
      programType: programType ?? this.programType,
      programDurationYears: programDurationYears ?? this.programDurationYears,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      startTerm: startTerm ?? this.startTerm,
      gpaScale: gpaScale ?? this.gpaScale,
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
    programType,
    programDurationYears,
    enrollmentDate,
    startTerm,
    gpaScale,
    totalCreditsRequired,
    retakePolicy,
  ];
}

/// Academic program classification
///
/// WHY THESE DISTINCTIONS MATTER:
/// - Bachelor's: 4 years, foundational, career-entry focused
/// - Master's: 1-2 years, specialized, higher GPA expectations
/// - Doctorate: 3-7 years, research-focused, different milestones
/// - Diploma: 2-3 years, vocational, practical focus
/// - Certificate: < 1 year, skill-specific, completion-focused
enum ProgramType {
  certificate, // < 1 year, skill credential
  diploma, // 2-3 years, technical/vocational
  bachelors, // 3-4 years, undergraduate degree
  honours, // 4-5 years, research component
  masters, // 1-2 years, postgraduate
  doctorate, // 3-7 years, PhD/professional doctorate
}

/// Academic term/semester designation
enum AcademicTerm {
  fall, // August - December
  spring, // January - May
  summer, // May - August (optional)
  winter, // December - January (optional)
}

enum RetakePolicy {
  replace, // Most recent grade replaces all
  average, // Average all attempts
  best, // Highest grade counts
}

/// Extension helpers for display
extension ProgramTypeExtension on ProgramType {
  String get displayName {
    switch (this) {
      case ProgramType.certificate:
        return 'Certificate';
      case ProgramType.diploma:
        return 'Diploma';
      case ProgramType.bachelors:
        return "Bachelor's Degree";
      case ProgramType.honours:
        return 'Honours Degree';
      case ProgramType.masters:
        return "Master's Degree";
      case ProgramType.doctorate:
        return 'Doctorate (PhD)';
    }
  }

  int get typicalDurationYears {
    switch (this) {
      case ProgramType.certificate:
        return 1;
      case ProgramType.diploma:
        return 2;
      case ProgramType.bachelors:
        return 4;
      case ProgramType.honours:
        return 4;
      case ProgramType.masters:
        return 2;
      case ProgramType.doctorate:
        return 5;
    }
  }
}

extension AcademicTermExtension on AcademicTerm {
  String get displayName {
    switch (this) {
      case AcademicTerm.fall:
        return 'Fall';
      case AcademicTerm.spring:
        return 'Spring';
      case AcademicTerm.summer:
        return 'Summer';
      case AcademicTerm.winter:
        return 'Winter';
    }
  }
}
