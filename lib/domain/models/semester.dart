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