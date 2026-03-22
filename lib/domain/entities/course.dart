import 'package:equatable/equatable.dart';

import 'assessment.dart';
import 'grading_schema.dart';

/// Course aggregates assessments and holds metadata for GPA computation.
class Course extends Equatable {
  final String id;
  final String semesterId;
  final String code;
  final String name;
  final int creditUnits;
  final List<Assessment> assessments;

  /// Whether this course is currently excluded from GPA (e.g., dropped/withdrawn).
  final bool isDropped;

  /// Optional override for grading schema; if null, inherit from semester/user default.
  final GradingSchema? gradingSchema;

  /// Optional retake info: attempt number and policy.
  final RetakeInfo? retakeInfo;

  const Course({
    required this.id,
    required this.semesterId,
    required this.code,
    required this.name,
    required this.creditUnits,
    this.assessments = const [],
    this.isDropped = false,
    this.gradingSchema,
    this.retakeInfo,
  });

  /// Total weight of non-dropped assessments (should be 1.0 for a complete course).
  double get effectiveWeightTotal => assessments
      .where((a) => !a.isDropped)
      .fold<double>(0, (sum, a) => sum + a.weightPercent);

  Course copyWith({
    String? id,
    String? semesterId,
    String? code,
    String? name,
    int? creditUnits,
    List<Assessment>? assessments,
    bool? isDropped,
    GradingSchema? gradingSchema,
    RetakeInfo? retakeInfo,
  }) {
    return Course(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      code: code ?? this.code,
      name: name ?? this.name,
      creditUnits: creditUnits ?? this.creditUnits,
      assessments: assessments ?? this.assessments,
      isDropped: isDropped ?? this.isDropped,
      gradingSchema: gradingSchema ?? this.gradingSchema,
      retakeInfo: retakeInfo ?? this.retakeInfo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    semesterId,
    code,
    name,
    creditUnits,
    assessments,
    isDropped,
    gradingSchema,
    retakeInfo,
  ];
}

class RetakeInfo extends Equatable {
  final String? originalCourseId;
  final RetakePolicy policy;
  final int attemptNumber; // 1 = first attempt

  const RetakeInfo({
    this.originalCourseId,
    required this.policy,
    this.attemptNumber = 1,
  });

  @override
  List<Object?> get props => [originalCourseId, policy, attemptNumber];
}

enum RetakePolicy { replace, average, best }
