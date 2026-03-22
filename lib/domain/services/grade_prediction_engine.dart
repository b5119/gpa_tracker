import 'dart:math' as math;

import '../entities/grading_config.dart';
import '../entities/past_course_performance.dart';

class GradePredictionResult {
  final double expectedGpa;
  final double bestCaseGpa;
  final double worstCaseGpa;
  final double confidence; // 0-1
  final String expectedLetter;
  final String summary;

  const GradePredictionResult({
    required this.expectedGpa,
    required this.bestCaseGpa,
    required this.worstCaseGpa,
    required this.confidence,
    required this.expectedLetter,
    required this.summary,
  });
}

class GradePredictionEngine {
  const GradePredictionEngine();

  /// Baseline: weighted moving average adjusted by difficulty and trend.
  GradePredictionResult predictBaseline({
    required List<PastCoursePerformance> history,
    required GradingConfig gradingConfig,
    int recentWindow = 6,
  }) {
    if (history.isEmpty) {
      return const GradePredictionResult(
        expectedGpa: 0,
        bestCaseGpa: 0,
        worstCaseGpa: 0,
        confidence: 0.3,
        expectedLetter: 'N/A',
        summary: 'Insufficient data',
      );
    }

    // Sort by completion date descending; take recent window for moving average.
    final sorted = [...history]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final window = sorted.take(recentWindow).toList();

    // Difficulty-adjusted weights: harder courses get slightly higher weight.
    // weight = credits * (1 + difficulty*0.05) * recencyFactor
    double weightedSum = 0;
    double weightTotal = 0;
    for (var i = 0; i < window.length; i++) {
      final course = window[i];
      final recency = 1.0 - (i * 0.05); // slight decay per position
      final difficultyFactor = 1 + (course.difficulty.clamp(1, 5) - 3) * 0.05;
      final w = course.credits * difficultyFactor * recency;
      weightedSum += course.gradePoint * w;
      weightTotal += w;
    }

    final wma = weightTotal == 0 ? 0 : weightedSum / weightTotal;

    // Trend: simple slope over window positions.
    final trendSlope = _trendSlope(window);
    final trendAdjusted = (wma + trendSlope).clamp(
      gradingConfig.minGPA,
      gradingConfig.maxGPA,
    );

    // Confidence: based on data volume and volatility.
    final volatility = _stdDev(window.map((e) => e.gradePoint).toList());
    final confidence = _confidence(window.length, volatility);

    final best = (trendAdjusted + volatility).clamp(
      gradingConfig.minGPA,
      gradingConfig.maxGPA,
    );
    final worst = (trendAdjusted - volatility).clamp(
      gradingConfig.minGPA,
      gradingConfig.maxGPA,
    );

    return GradePredictionResult(
      expectedGpa: trendAdjusted,
      bestCaseGpa: best,
      worstCaseGpa: worst,
      confidence: confidence,
      expectedLetter: gradingConfig.getClassification(trendAdjusted).name,
      summary: _summary(
        confidence,
        gradingConfig.getClassification(trendAdjusted).name,
      ),
    );
  }

  /// Advanced: regression + confidence interval + simple course-similarity weighting.
  GradePredictionResult predictAdvanced({
    required List<PastCoursePerformance> history,
    required GradingConfig gradingConfig,
  }) {
    if (history.length < 3) {
      return predictBaseline(history: history, gradingConfig: gradingConfig);
    }

    // Regression on chronological GPA sequence.
    final sorted = [...history]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final gpas = sorted.map((e) => e.gradePoint).toList();
    final regression = _linearRegression(gpas);
    final nextIndex = gpas.length; // predict next period
    final projected = (regression.slope * nextIndex + regression.intercept)
        .clamp(gradingConfig.minGPA, gradingConfig.maxGPA);

    final sigma = _stdDev(gpas);
    final best = (projected + 1.0 * sigma).clamp(
      gradingConfig.minGPA,
      gradingConfig.maxGPA,
    );
    final worst = (projected - 1.0 * sigma).clamp(
      gradingConfig.minGPA,
      gradingConfig.maxGPA,
    );

    // Confidence uses R^2 and volatility.
    final confidence = _confidenceAdvanced(regression.r2, gpas.length, sigma);

    // Course similarity: upweight recent courses with same subject prefix.
    final similarityBoost = _similarityBoost(sorted, projected);
    final projectedBoosted = (projected + similarityBoost).clamp(
      gradingConfig.minGPA,
      gradingConfig.maxGPA,
    );

    return GradePredictionResult(
      expectedGpa: projectedBoosted,
      bestCaseGpa: best,
      worstCaseGpa: worst,
      confidence: confidence,
      expectedLetter: gradingConfig.getClassification(projectedBoosted).name,
      summary: _summary(
        confidence,
        gradingConfig.getClassification(projectedBoosted).name,
      ),
    );
  }

  double _trendSlope(List<PastCoursePerformance> window) {
    if (window.length < 2) return 0;
    // x = 0..n-1 (recent first), y = gradePoint
    final n = window.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = window[i].gradePoint;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    final denom = (n * sumX2) - (sumX * sumX);
    if (denom == 0) return 0;
    return ((n * sumXY) - (sumX * sumY)) / denom;
  }

  double _stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }

  double _confidence(int samples, double volatility) {
    final sampleScore = math.min(1.0, samples / 6); // saturate at 6 samples
    final volatilityScore = math.max(0, 1 - (volatility / 0.6));
    return (0.6 * sampleScore) + (0.4 * volatilityScore);
  }

  double _confidenceAdvanced(double r2, int samples, double sigma) {
    final double r2Clamped = r2.clamp(0.0, 1.0).toDouble();
    final r2Score = r2Clamped * 0.5;
    final sampleScore = math.min(1.0, samples / 8) * 0.3;
    final volatilityScore = math.max(0, 1 - (sigma / 0.6)) * 0.2;
    return r2Score + sampleScore + volatilityScore;
  }

  _RegressionResult _linearRegression(List<double> y) {
    final n = y.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final yi = y[i];
      sumX += x;
      sumY += yi;
      sumXY += x * yi;
      sumX2 += x * x;
      sumY2 += yi * yi;
    }
    final denom = (n * sumX2) - (sumX * sumX);
    final double slope = denom == 0
        ? 0.0
        : ((n * sumXY) - (sumX * sumY)) / denom;
    final double intercept = (sumY - slope * sumX) / n;
    final double ssTot = sumY2 - ((sumY * sumY) / n);
    final ssRes = List.generate(n, (i) {
      final x = i.toDouble();
      final pred = slope * x + intercept;
      final diff = y[i] - pred;
      return diff * diff;
    }).reduce((a, b) => a + b);
    final r2 = ssTot == 0 ? 0.0 : (1.0 - (ssRes / ssTot));
    return _RegressionResult(slope: slope, intercept: intercept, r2: r2);
  }

  double _similarityBoost(
    List<PastCoursePerformance> sorted,
    double projected,
  ) {
    if (sorted.isEmpty) return 0;
    final recent = sorted.last; // most recent course
    final prefix = _prefix(recent.courseCode);
    final similar = sorted
        .where((c) => _prefix(c.courseCode) == prefix)
        .toList();
    if (similar.length < 2) return 0;
    final avg =
        similar.map((c) => c.gradePoint).reduce((a, b) => a + b) /
        similar.length;
    // Small pull toward similar-course average (10%)
    return (avg - projected) * 0.1;
  }

  String _prefix(String code) {
    final match = RegExp(r'^[A-Za-z]+').firstMatch(code);
    return match?.group(0) ?? code;
  }

  String _summary(double confidence, String letter) {
    final pct = (confidence * 100).clamp(0, 100).toStringAsFixed(0);
    return '$pct% chance of $letter or higher';
  }
}

class _RegressionResult {
  final double slope;
  final double intercept;
  final double r2;

  _RegressionResult({
    required this.slope,
    required this.intercept,
    required this.r2,
  });
}
