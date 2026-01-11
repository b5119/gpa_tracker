import 'dart:math' as math;

/// Analyze GPA trends over time with academic interpretation
///
/// WHY ANALYTICS INFORM RECOMMENDATIONS:
///
/// Raw GPA history: [3.2, 3.3, 3.4, 3.5]
/// Without analytics: "Your GPA is 3.5"
/// With analytics: "You are improving steadily (+0.1/semester), highly consistent (σ=0.13),
///                  strong upward trend (slope=0.1, R²=0.99)"
///
/// This enables:
/// - Early warning systems (declining trends)
/// - Motivation (quantified improvement)
/// - Realistic predictions (trend + volatility)
/// - Intervention targeting (high volatility = unstable study habits)
///
/// ACADEMIC INTERPRETATION OF VOLATILITY (σ):
///
/// σ < 0.15: Very Consistent
/// - Stable study habits
/// - Predictable performance
/// - Reliable for forecasting
/// - Indicates mastery or struggle (check mean)
///
/// σ 0.15-0.30: Moderately Consistent
/// - Some course difficulty variation
/// - Normal for most students
/// - Manageable variance
///
/// σ > 0.30: High Volatility
/// - Inconsistent performance
/// - May indicate:
///   * Poor time management
///   * Course selection issues
///   * External life factors
///   * Mental health concerns
/// - Requires investigation
class AnalyzeGPATrend {
  /// Analyze historical GPA performance
  TrendAnalysisResult execute({
    required List<double> semesterGPAs,
  }) {
    if (semesterGPAs.isEmpty) {
      return TrendAnalysisResult.empty();
    }

    if (semesterGPAs.length == 1) {
      return TrendAnalysisResult(
        meanGPA: semesterGPAs.first,
        standardDeviation: 0.0,
        trendSlope: 0.0,
        trendIntercept: semesterGPAs.first,
        rSquared: 0.0,
        classification: TrendClassification.insufficient,
        semesterCount: 1,
        highestGPA: semesterGPAs.first,
        lowestGPA: semesterGPAs.first,
        semesterDeltas: [],
      );
    }

    // Calculate descriptive statistics
    final mean = _calculateMean(semesterGPAs);
    final stdDev = _calculateStandardDeviation(semesterGPAs, mean);

    // Calculate trend via linear regression
    final trend = _calculateLinearRegression(semesterGPAs);

    // Classify trend
    final classification = _classifyTrend(trend.slope, stdDev);

    // Semester-to-semester changes
    final deltas = _calculateDeltas(semesterGPAs);

    return TrendAnalysisResult(
      meanGPA: mean,
      standardDeviation: stdDev,
      trendSlope: trend.slope,
      trendIntercept: trend.intercept,
      rSquared: trend.rSquared,
      classification: classification,
      semesterCount: semesterGPAs.length,
      highestGPA: semesterGPAs.reduce(math.max),
      lowestGPA: semesterGPAs.reduce(math.min),
      semesterDeltas: deltas,
    );
  }

  double _calculateMean(List<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.length < 2) return 0.0;

    final squaredDiffs = values.map((x) => math.pow(x - mean, 2));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;

    return math.sqrt(variance);
  }

  _TrendData _calculateLinearRegression(List<double> gpas) {
    final n = gpas.length;
    final xValues = List.generate(n, (i) => i.toDouble());
    final yValues = gpas;

    final sumX = xValues.reduce((a, b) => a + b);
    final sumY = yValues.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => xValues[i] * yValues[i])
        .reduce((a, b) => a + b);
    final sumX2 = xValues.map((x) => x * x).reduce((a, b) => a + b);

    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator = (n * sumX2) - (sumX * sumX);

    if (denominator == 0) {
      return _TrendData(
        slope: 0.0,
        intercept: sumY / n,
        rSquared: 0.0,
      );
    }

    final slope = numerator / denominator;
    final intercept = (sumY - slope * sumX) / n;

    // Calculate R²
    final meanY = sumY / n;
    final ssTotal = yValues.map((y) => math.pow(y - meanY, 2)).reduce((a, b) => a + b);
    final ssResidual = List.generate(n, (i) {
      final predicted = slope * xValues[i] + intercept;
      return math.pow(yValues[i] - predicted, 2);
    }).reduce((a, b) => a + b);

    final rSquared = ssTotal > 0 ? 1 - (ssResidual / ssTotal) : 0.0;

    return _TrendData(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared.clamp(0.0, 1.0),
    );
  }

  TrendClassification _classifyTrend(double slope, double stdDev) {
    const significantSlope = 0.05;
    const volatilityThreshold = 0.3;

    if (stdDev > volatilityThreshold) {
      return TrendClassification.volatile;
    }

    if (slope > significantSlope) {
      return TrendClassification.improving;
    } else if (slope < -significantSlope) {
      return TrendClassification.declining;
    } else {
      // Stable - determine if high or low
      return TrendClassification.stable;
    }
  }

  List<SemesterDelta> _calculateDeltas(List<double> gpas) {
    if (gpas.length < 2) return [];

    final deltas = <SemesterDelta>[];

    for (int i = 1; i < gpas.length; i++) {
      final delta = gpas[i] - gpas[i - 1];

      deltas.add(SemesterDelta(
        fromSemester: i - 1,
        toSemester: i,
        fromGPA: gpas[i - 1],
        toGPA: gpas[i],
        change: delta,
        significance: _categorizeDelta(delta),
      ));
    }

    return deltas;
  }

  DeltaSignificance _categorizeDelta(double delta) {
    if (delta.abs() < 0.1) return DeltaSignificance.negligible;
    if (delta > 0.3) return DeltaSignificance.majorImprovement;
    if (delta > 0.1) return DeltaSignificance.improvement;
    if (delta < -0.3) return DeltaSignificance.majorDecline;
    return DeltaSignificance.decline;
  }
}

class _TrendData {
  final double slope;
  final double intercept;
  final double rSquared;

  const _TrendData({
    required this.slope,
    required this.intercept,
    required this.rSquared,
  });
}

/// Result of trend analysis
class TrendAnalysisResult {
  final double meanGPA;
  final double standardDeviation;
  final double trendSlope;
  final double trendIntercept;
  final double rSquared;
  final TrendClassification classification;
  final int semesterCount;
  final double highestGPA;
  final double lowestGPA;
  final List<SemesterDelta> semesterDeltas;

  const TrendAnalysisResult({
    required this.meanGPA,
    required this.standardDeviation,
    required this.trendSlope,
    required this.trendIntercept,
    required this.rSquared,
    required this.classification,
    required this.semesterCount,
    required this.highestGPA,
    required this.lowestGPA,
    required this.semesterDeltas,
  });

  factory TrendAnalysisResult.empty() {
    return const TrendAnalysisResult(
      meanGPA: 0.0,
      standardDeviation: 0.0,
      trendSlope: 0.0,
      trendIntercept: 0.0,
      rSquared: 0.0,
      classification: TrendClassification.insufficient,
      semesterCount: 0,
      highestGPA: 0.0,
      lowestGPA: 0.0,
      semesterDeltas: [],
    );
  }

  double get gpaRange => highestGPA - lowestGPA;

  double get coefficientOfVariation =>
      meanGPA > 0 ? standardDeviation / meanGPA : 0.0;

  String get consistencyRating {
    if (standardDeviation < 0.15) return 'Highly Consistent';
    if (standardDeviation < 0.30) return 'Moderately Consistent';
    if (standardDeviation < 0.50) return 'Somewhat Variable';
    return 'Highly Variable';
  }

  String get trendDescription {
    switch (classification) {
      case TrendClassification.improving:
        return 'Improving steadily (${trendSlope >= 0 ? '+' : ''}${trendSlope.toStringAsFixed(3)}/semester)';
      case TrendClassification.declining:
        return 'Declining trend (${trendSlope.toStringAsFixed(3)}/semester) - needs attention';
      case TrendClassification.stable:
        return 'Stable performance';
      case TrendClassification.volatile:
        return 'Highly variable - inconsistent performance';
      case TrendClassification.insufficient:
        return 'Insufficient data for trend analysis';
    }
  }
}

enum TrendClassification {
  improving,
  declining,
  stable,
  volatile,
  insufficient,
}

class SemesterDelta {
  final int fromSemester;
  final int toSemester;
  final double fromGPA;
  final double toGPA;
  final double change;
  final DeltaSignificance significance;

  const SemesterDelta({
    required this.fromSemester,
    required this.toSemester,
    required this.fromGPA,
    required this.toGPA,
    required this.change,
    required this.significance,
  });

  String get displayChange {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}';
  }
}

enum DeltaSignificance {
  majorImprovement,
  improvement,
  negligible,
  decline,
  majorDecline,
}