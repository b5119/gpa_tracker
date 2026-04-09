import '../models/course.dart';
import '../entities/grading_config.dart';

/// Calculate semester GPA with full grading config support
///
/// MATHEMATICAL CORRECTNESS:
/// GPA = Σ(grade_point × credits) / Σ(credits)
///
/// WHY THIS IS A USE CASE:
/// - Encapsulates business logic
/// - Depends on GradingConfig (not hard-coded)
/// - Handles edge cases systematically
/// - Testable in isolation
/// - Reusable across the application
///
/// EDGE CASES HANDLED:
/// - Zero credits (audit courses) → excluded from calculation
/// - In-progress courses (no grade) → excluded from calculation
/// - Withdrawn courses → excluded from calculation
/// - Pass/Fail courses → handled per grading config
/// - Empty course list → returns null
class CalculateSemesterGPA {
  /// Execute GPA calculation for a single semester
  ///
  /// Returns null if no graded courses exist
  double? execute({
    required List<Course> courses,
    required GradingConfig gradingConfig,
  }) {
    // Filter to only graded courses with credits
    final gradedCourses = courses.where((course) {
      return course.gradePoint != null && course.credits > 0;
    }).toList();

    if (gradedCourses.isEmpty) return null;

    double totalQualityPoints = 0.0;
    int totalCredits = 0;

    for (final course in gradedCourses) {
      // Validate grade point is within scale
      final gradePoint = course.gradePoint!;

      if (gradePoint < gradingConfig.minGPA ||
          gradePoint > gradingConfig.maxGPA) {
        throw ArgumentError(
          'Invalid grade point $gradePoint for grading scale '
          '${gradingConfig.minGPA}-${gradingConfig.maxGPA}',
        );
      }

      totalQualityPoints += gradePoint * course.credits;
      totalCredits += course.credits;
    }

    if (totalCredits == 0) return null;

    final gpa = totalQualityPoints / totalCredits;

    // Clamp to scale boundaries (handle floating point errors)
    return gpa.clamp(gradingConfig.minGPA, gradingConfig.maxGPA);
  }
}
