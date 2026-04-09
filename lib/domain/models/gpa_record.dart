import 'package:equatable/equatable.dart';

class GPARecord extends Equatable {
  final String studentId;
  final DateTime calculatedAt;
  final double cumulativeGPA;
  final double? semesterGPA;
  final int totalCreditsAttempted;
  final int totalCreditsEarned;
  final double totalQualityPoints;
  final String? semesterId;

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

  AcademicStanding get academicStanding {
    if (cumulativeGPA >= 3.5) return AcademicStanding.deansList;
    if (cumulativeGPA >= 3.0) return AcademicStanding.goodStanding;
    if (cumulativeGPA >= 2.0) return AcademicStanding.satisfactory;
    if (cumulativeGPA >= 1.0) return AcademicStanding.probation;
    return AcademicStanding.academicDismissal;
  }

  factory GPARecord.fromJson(Map<String, dynamic> json) {
    return GPARecord(
      studentId: json['student_id'] as String,
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
      cumulativeGPA: (json['cumulative_gpa'] as num).toDouble(),
      semesterGPA: (json['semester_gpa'] as num?)?.toDouble(),
      totalCreditsAttempted: json['total_credits_attempted'] as int,
      totalCreditsEarned: json['total_credits_earned'] as int,
      totalQualityPoints: (json['total_quality_points'] as num).toDouble(),
      semesterId: json['semester_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'calculated_at': calculatedAt.toIso8601String(),
      'cumulative_gpa': cumulativeGPA,
      'semester_gpa': semesterGPA,
      'total_credits_attempted': totalCreditsAttempted,
      'total_credits_earned': totalCreditsEarned,
      'total_quality_points': totalQualityPoints,
      'semester_id': semesterId,
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
  deansList,
  goodStanding,
  satisfactory,
  probation,
  academicDismissal,
}
