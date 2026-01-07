
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
