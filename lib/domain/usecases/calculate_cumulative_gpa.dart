import '../models/student.dart';
import '../models/course.dart';
import '../entities/grading_config.dart';

/// Calculate cumulative GPA across all semesters with retake policy
///
/// WHY RETAKE POLICIES MATTER:
///
/// Students frequently retake courses to improve grades. Institutions
/// handle this differently:
///
/// REPLACE (Most Common):
/// - Only most recent attempt counts
/// - Example: F → C means only C affects GPA
/// - Pro: Encourages improvement
/// - Con: Doesn't reflect full academic journey
///
/// AVERAGE:
/// - All attempts averaged
/// - Example: F (0.0) + C (2.0) = 1.0 average
/// - Pro: More accurate reflection of performance
/// - Con: Penalizes students who improve
///
/// BEST:
/// - Highest grade across attempts
/// - Example: F → C → B means B counts
/// - Pro: Most lenient, rewards peak performance
/// - Con: Rarely used, may misrepresent ability
///
/// The policy choice significantly impacts calculated GPA and must be
/// configurable per institution.
class CalculateCumulativeGPA {
  /// Execute cumulative GPA calculation
  CumulativeGPAResult execute({
    required Map<String, List<Course>> semesterCourses,
    required RetakePolicy retakePolicy,
    required GradingConfig gradingConfig,
  }) {
    // Flatten all courses across semesters
    final allCourses = semesterCourses.values
        .expand((courses) => courses)
        .toList();

    // Group by course code to identify retakes
    final courseGroups = <String, List<Course>>{};
    for (final course in allCourses) {
      final key = course.courseCode.toUpperCase();
      courseGroups.putIfAbsent(key, () => []).add(course);
    }

    // Apply retake policy
    final finalCourses = <Course>[];
    int retakesProcessed = 0;

    for (final entry in courseGroups.entries) {
      final attempts = entry.value;

      if (attempts.length > 1) {
        retakesProcessed++;
        final resolvedCourse = _applyRetakePolicy(
          attempts,
          retakePolicy,
          gradingConfig,
        );
        if (resolvedCourse != null) {
          finalCourses.add(resolvedCourse);
        }
      } else {
        finalCourses.add(attempts.first);
      }
    }

    // Calculate GPA from final courses
    final gradedCourses = finalCourses
        .where((c) => c.gradePoint != null)
        .toList();

    if (gradedCourses.isEmpty) {
      return CumulativeGPAResult(
        gpa: 0.0,
        totalCreditsAttempted: 0,
        totalCreditsEarned: 0,
        totalQualityPoints: 0.0,
        coursesIncluded: 0,
        retakesProcessed: 0,
      );
    }

    double totalQualityPoints = 0.0;
    int totalCreditsAttempted = 0;
    int totalCreditsEarned = 0;

    for (final course in finalCourses) {
      totalCreditsAttempted += course.credits;

      if (course.gradePoint != null) {
        totalQualityPoints += course.gradePoint! * course.credits;

        // Credits earned if passing grade
        if (course.gradePoint! >=
            gradingConfig.minGPA +
                ((gradingConfig.maxGPA - gradingConfig.minGPA) * 0.5)) {
          totalCreditsEarned += course.credits;
        }
      }
    }

    final gpa = totalCreditsAttempted > 0
        ? totalQualityPoints / totalCreditsAttempted
        : 0.0;

    return CumulativeGPAResult(
      gpa: gpa.clamp(gradingConfig.minGPA, gradingConfig.maxGPA),
      totalCreditsAttempted: totalCreditsAttempted,
      totalCreditsEarned: totalCreditsEarned,
      totalQualityPoints: totalQualityPoints,
      coursesIncluded: finalCourses.length,
      retakesProcessed: retakesProcessed,
    );
  }

  /// Apply retake policy to determine final grade
  Course? _applyRetakePolicy(
    List<Course> attempts,
    RetakePolicy policy,
    GradingConfig gradingConfig,
  ) {
    // Filter to graded attempts
    final graded = attempts.where((c) => c.gradePoint != null).toList();
    if (graded.isEmpty) return attempts.last;

    // Sort by attempt number
    graded.sort((a, b) => a.attemptNumber.compareTo(b.attemptNumber));

    switch (policy) {
      case RetakePolicy.replace:
        // Most recent graded attempt
        return graded.last;

      case RetakePolicy.average:
        // Create synthetic course with averaged grade
        final avgGrade =
            graded.map((c) => c.gradePoint!).reduce((a, b) => a + b) /
            graded.length;

        return graded.first.copyWith(
          gradePoint: avgGrade.clamp(
            gradingConfig.minGPA,
            gradingConfig.maxGPA,
          ),
        );

      case RetakePolicy.best:
        // Highest grade
        return graded.reduce(
          (best, current) =>
              current.gradePoint! > best.gradePoint! ? current : best,
        );
    }
  }
}

/// Result of cumulative GPA calculation
class CumulativeGPAResult {
  final double gpa;
  final int totalCreditsAttempted;
  final int totalCreditsEarned;
  final double totalQualityPoints;
  final int coursesIncluded;
  final int retakesProcessed;

  const CumulativeGPAResult({
    required this.gpa,
    required this.totalCreditsAttempted,
    required this.totalCreditsEarned,
    required this.totalQualityPoints,
    required this.coursesIncluded,
    required this.retakesProcessed,
  });

  /// GPA formatted for display
  String get displayGPA => gpa.toStringAsFixed(2);

  /// Completion rate (earned / attempted)
  double get completionRate {
    return totalCreditsAttempted > 0
        ? totalCreditsEarned / totalCreditsAttempted
        : 0.0;
  }
}
