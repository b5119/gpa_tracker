import '../models/semester.dart';

class TargetGpaPlan {
  final double targetCgpa;
  final double currentCgpa;
  final int completedCredits;
  final int remainingCredits;
  final int totalCredits;
  final double currentGradePoints;
  final double requiredFutureGpa;
  final bool achievable;
  final List<PerCourseRecommendation> recommendations;

  const TargetGpaPlan({
    required this.targetCgpa,
    required this.currentCgpa,
    required this.completedCredits,
    required this.remainingCredits,
    required this.totalCredits,
    required this.currentGradePoints,
    required this.requiredFutureGpa,
    required this.achievable,
    required this.recommendations,
  });
}

class PerCourseRecommendation {
  final String courseId;
  final String courseName;
  final int credits;
  final double requiredGpa;
  final String suggestedLetter;

  const PerCourseRecommendation({
    required this.courseId,
    required this.courseName,
    required this.credits,
    required this.requiredGpa,
    required this.suggestedLetter,
  });
}

class TargetGpaCalculator {
  const TargetGpaCalculator();

  TargetGpaPlan? calculatePlan({
    required double targetCgpa,
    required double currentCgpa,
    required int totalCredits,
    required List<Semester> semesters,
    required double maxGpa,
  }) {
    final completedSemesters = semesters
        .where((s) => s.status == SemesterStatus.completed)
        .toList();
    final completedCredits = completedSemesters.fold<int>(
      0,
      (sum, s) => sum + s.earnedCredits,
    );
    final remainingCredits = totalCredits - completedCredits;
    if (totalCredits <= 0) return null;

    final currentGradePoints = currentCgpa * completedCredits;

    if (remainingCredits <= 0) {
      final achievable = currentCgpa >= targetCgpa;
      return TargetGpaPlan(
        targetCgpa: targetCgpa,
        currentCgpa: currentCgpa,
        completedCredits: completedCredits,
        remainingCredits: 0,
        totalCredits: totalCredits,
        currentGradePoints: currentGradePoints,
        requiredFutureGpa: 0,
        achievable: achievable,
        recommendations: const [],
      );
    }

    final requiredFutureGpa =
        ((targetCgpa * totalCredits) - currentGradePoints) / remainingCredits;
    final cappedRequired = requiredFutureGpa.clamp(0.0, maxGpa) as double;
    final achievable = requiredFutureGpa <= maxGpa;

    final upcomingSemesters = semesters
        .where((s) => s.status != SemesterStatus.completed)
        .toList();
    final futureCourses = upcomingSemesters.expand((s) => s.courses).toList();

    final recommendations = futureCourses.map((course) {
      return PerCourseRecommendation(
        courseId: course.id,
        courseName: course.courseName,
        credits: course.credits,
        requiredGpa: cappedRequired,
        suggestedLetter: _letterForGpa(cappedRequired, maxGpa),
      );
    }).toList();

    return TargetGpaPlan(
      targetCgpa: targetCgpa,
      currentCgpa: currentCgpa,
      completedCredits: completedCredits,
      remainingCredits: remainingCredits,
      totalCredits: totalCredits,
      currentGradePoints: currentGradePoints,
      requiredFutureGpa: cappedRequired,
      achievable: achievable,
      recommendations: recommendations,
    );
  }

  String _letterForGpa(double gpa, double maxGpa) {
    final scale = maxGpa >= 5 ? 5.0 : 4.0;
    final normalized = gpa / scale;
    if (normalized >= 0.93) return 'A';
    if (normalized >= 0.9) return 'A-';
    if (normalized >= 0.87) return 'B+';
    if (normalized >= 0.83) return 'B';
    if (normalized >= 0.8) return 'B-';
    if (normalized >= 0.77) return 'C+';
    if (normalized >= 0.73) return 'C';
    if (normalized >= 0.7) return 'C-';
    if (normalized >= 0.67) return 'D+';
    if (normalized >= 0.63) return 'D';
    if (normalized >= 0.6) return 'D-';
    return 'F';
  }
}
