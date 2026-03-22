import 'package:equatable/equatable.dart';

/// GradingSchema encapsulates how raw scores or letter grades map to GPA points.
/// Supports three modes:
/// - letter: grade letters map to points via `letterToPoint`
/// - percentage: percentages map to points using thresholds
/// - directPoints: raw scores are already GPA points (clamped to scale)
class GradingSchema extends Equatable {
  final String id;
  final String name;
  final GradingMode mode;
  final double maxGpa; // e.g., 4.0 or 5.0
  final double minGpa; // usually 0.0

  /// Letter grade → grade point mapping (used in letter mode)
  final Map<String, double> letterToPoint;

  /// Percentage thresholds mapping to grade points (used in percentage mode).
  /// Expect keys as lower bounds (0-100), values as GPA points.
  /// Example: {90: 4.0, 80: 3.0, 70: 2.0, 60: 1.0, 0: 0.0}
  final Map<double, double> percentageBands;

  const GradingSchema({
    required this.id,
    required this.name,
    required this.mode,
    required this.maxGpa,
    this.minGpa = 0.0,
    this.letterToPoint = const {},
    this.percentageBands = const {},
  });

  /// Resolve grade point for a letter grade.
  double? gradePointForLetter(String letter) {
    return letterToPoint[letter];
  }

  /// Resolve grade point for a percentage score (0-100).
  double? gradePointForPercentage(double percentage) {
    if (percentage.isNaN) return null;
    final clamped = percentage.clamp(0, 100);
    double? best;
    double? bestThreshold;
    percentageBands.forEach((threshold, gpa) {
      if (clamped >= threshold) {
        if (bestThreshold == null || threshold > bestThreshold!) {
          bestThreshold = threshold;
          best = gpa;
        }
      }
    });
    return best;
  }

  /// Resolve grade point when raw score is already a GPA point.
  double gradePointForDirect(double rawPoints) {
    return rawPoints.clamp(minGpa, maxGpa);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    mode,
    maxGpa,
    minGpa,
    letterToPoint,
    percentageBands,
  ];
}

enum GradingMode { letter, percentage, directPoints }
