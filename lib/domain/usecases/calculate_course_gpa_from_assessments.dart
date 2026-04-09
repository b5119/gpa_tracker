import '../entities/assessment.dart';
import '../entities/grading_schema.dart';

class CourseGPAResult {
  final double weightedPercentage;
  final double gradePoint;
  final List<String> warnings;

  const CourseGPAResult({
    required this.weightedPercentage,
    required this.gradePoint,
    this.warnings = const [],
  });
}

class CalculateCourseGPAFromAssessments {
  CourseGPAResult execute({
    required List<Assessment> assessments,
    required GradingSchema gradingSchema,
  }) {
    if (assessments.isEmpty) {
      return const CourseGPAResult(
        weightedPercentage: 0,
        gradePoint: 0,
        warnings: ['No assessments provided'],
      );
    }

    final active = assessments
        .where((a) => a.pointsEarned != null && a.totalPoints > 0)
        .toList();
    if (active.isEmpty) {
      return const CourseGPAResult(
        weightedPercentage: 0,
        gradePoint: 0,
        warnings: ['No graded assessments'],
      );
    }

    final weightSum = active.fold<double>(0, (sum, a) => sum + a.weightPercent);
    final warnings = <String>[];
    if (weightSum <= 0) {
      return const CourseGPAResult(
        weightedPercentage: 0,
        gradePoint: 0,
        warnings: ['Total weight is zero'],
      );
    }
    if ((weightSum - 100).abs() > 0.01) {
      warnings.add(
        'Weights do not sum to 100% (current: ${weightSum.toStringAsFixed(2)}).',
      );
    }

    double weighted = 0;
    for (final a in active) {
      // Guard against division by zero
      if (a.totalPoints > 0) {
        final percent = (a.pointsEarned! / a.totalPoints) * 100;
        weighted += percent * (a.weightPercent / 100);
      }
    }

    final normalized =
        weighted * (100 / weightSum); // normalize if weights != 100
    final gradePoint = _toGradePoint(normalized, gradingSchema) ?? 0;

    return CourseGPAResult(
      weightedPercentage: normalized,
      gradePoint: gradePoint,
      warnings: warnings,
    );
  }

  double? _toGradePoint(double percent, GradingSchema schema) {
    switch (schema.mode) {
      case GradingMode.letter:
        // Cannot map percent without bands; rely on percentageBands.
        return schema.gradePointForPercentage(percent);
      case GradingMode.percentage:
        return schema.gradePointForPercentage(percent);
      case GradingMode.directPoints:
        return schema.gradePointForDirect(percent);
    }
  }
}
