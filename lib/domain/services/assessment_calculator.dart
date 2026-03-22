import '../entities/assessment.dart';

class AssessmentCalculator {
  /// Returns weighted percentage (0-100). Ignores dropped or ungraded assessments.
  double? calculateCoursePercentage(List<Assessment> assessments) {
    final active = assessments
        .where((a) => !a.isDropped && a.pointsEarned != null)
        .toList();
    if (active.isEmpty) return null;

    double weightedSum = 0;
    double weightTotal = 0;

    for (final assessment in active) {
      final percent = assessment.percentScore;
      if (percent == null) continue;
      weightedSum += percent * (assessment.weightPercent / 100);
      weightTotal += assessment.weightPercent;
    }

    if (weightTotal == 0) return null;

    // Normalize by total weight in case it does not equal 100 exactly.
    return weightedSum * (100 / weightTotal);
  }
}
