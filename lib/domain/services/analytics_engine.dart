// =============================================================================
// STATISTICAL ANALYSIS & PREDICTION ENGINE
// =============================================================================
// This module performs historical GPA analysis and predictive modeling.
//
// ACADEMIC JUSTIFICATION:
// - Trend analysis helps identify performance patterns
// - Volatility measurement indicates consistency
// - Linear regression provides reasonable short-term forecasts
// - Scenario modeling helps with strategic planning
//
// MATHEMATICAL FOUNDATION:
// - Uses least-squares linear regression for trend detection
// - Standard deviation for volatility
// - Confidence intervals based on historical variance
// - Monte Carlo simulation for scenario generation

import 'dart:math' as math;

/// Statistical analysis and forecasting engine for academic performance.
///
/// This service analyzes historical GPA data to detect trends, measure
/// consistency, and generate predictions. It uses classical statistical
/// methods appropriate for small datasets typical of student transcripts.
class GPAAnalyticsEngine {
  /// Analyzes historical GPA performance across semesters.
  ///
  /// WHAT IT CALCULATES:
  /// 1. Mean GPA - Central tendency
  /// 2. Standard deviation - Consistency measure
  /// 3. Trend slope - Rate of improvement/decline
  /// 4. Performance classification - Trajectory categorization
  ///
  /// WHY THESE METRICS MATTER:
  /// - Mean GPA: Overall academic level
  /// - Std Dev: Volatility indicates reliability and stress factors
  /// - Trend: Improvement trajectory affects career prospects
  /// - Classification: Simplifies complex patterns for users
  ///
  /// [semesterGPAs] - List of GPAs in chronological order
  /// Returns: Comprehensive performance analysis
  PerformanceAnalysis analyzePerformance(List<double> semesterGPAs) {
    if (semesterGPAs.isEmpty) {
      return PerformanceAnalysis.empty();
    }

    final mean = _calculateMean(semesterGPAs);
    final stdDev = _calculateStandardDeviation(semesterGPAs, mean);
    final trend = _calculateTrend(semesterGPAs);
    final classification = _classifyPerformance(trend, stdDev);

    return PerformanceAnalysis(
      meanGPA: mean,
      standardDeviation: stdDev,
      trendSlope: trend.slope,
      trendIntercept: trend.intercept,
      classification: classification,
      semesterCount: semesterGPAs.length,
      highestGPA: semesterGPAs.reduce(math.max),
      lowestGPA: semesterGPAs.reduce(math.min),
      rSquared: trend.rSquared,
    );
  }

  /// Calculates arithmetic mean.
  /// Formula: μ = Σx / n
  double _calculateMean(List<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculates population standard deviation.
  ///
  /// Formula: σ = √(Σ(x - μ)² / n)
  ///
  /// ACADEMIC INTERPRETATION:
  /// - σ < 0.2: Very consistent performance
  /// - σ 0.2-0.4: Moderate variability
  /// - σ > 0.4: High volatility (investigate causes)
  ///
  /// High volatility may indicate:
  /// - Course difficulty variation
  /// - Inconsistent study habits
  /// - External life factors
  /// - Major changes or transitions
  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.length < 2) return 0.0;

    final squaredDifferences = values.map((x) => math.pow(x - mean, 2)).toList();
    final variance = squaredDifferences.reduce((a, b) => a + b) / values.length;

    return math.sqrt(variance);
  }

  /// Calculates linear trend using least-squares regression.
  ///
  /// MATHEMATICAL METHOD:
  /// Fits line y = mx + b to data points where:
  /// - y = GPA
  /// - x = semester index (0, 1, 2, ...)
  ///
  /// Formulas:
  /// m = (n·Σxy - Σx·Σy) / (n·Σx² - (Σx)²)
  /// b = (Σy - m·Σx) / n
  ///
  /// WHY LINEAR REGRESSION:
  /// - Simple and interpretable
  /// - Appropriate for short time series (4-8 semesters)
  /// - Provides directional insight
  /// - Slope indicates rate of change per semester
  ///
  /// LIMITATIONS:
  /// - Assumes linear trend (GPA changes rarely purely linear)
  /// - Sensitive to outliers
  /// - Poor for long-term forecasting (>4 semesters ahead)
  /// - Doesn't capture seasonality or external factors
  TrendResult _calculateTrend(List<double> gpas) {
    if (gpas.length < 2) {
      return TrendResult(slope: 0.0, intercept: gpas.first, rSquared: 0.0);
    }

    final n = gpas.length;
    final xValues = List.generate(n, (i) => i.toDouble());
    final yValues = gpas;

    // Calculate sums needed for regression
    final sumX = xValues.reduce((a, b) => a + b);
    final sumY = yValues.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => xValues[i] * yValues[i])
        .reduce((a, b) => a + b);
    final sumX2 = xValues.map((x) => x * x).reduce((a, b) => a + b);

    // Calculate slope (m)
    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator = (n * sumX2) - (sumX * sumX);

    if (denominator == 0) {
      return TrendResult(slope: 0.0, intercept: sumY / n, rSquared: 0.0);
    }

    final slope = numerator / denominator;

    // Calculate intercept (b)
    final intercept = (sumY - slope * sumX) / n;

    // Calculate R² (coefficient of determination)
    final meanY = sumY / n;
    final ssTotal = yValues.map((y) => math.pow(y - meanY, 2)).reduce((a, b) => a + b);
    final ssResidual = List.generate(n, (i) {
      final predicted = slope * xValues[i] + intercept;
      return math.pow(yValues[i] - predicted, 2);
    }).reduce((a, b) => a + b);

    final rSquared = ssTotal > 0 ? 1 - (ssResidual / ssTotal) : 0.0;

    return TrendResult(
      slope: slope,
      intercept: intercept,
      rSquared: math.max(0, math.min(1, rSquared)),
    );
  }

  /// Classifies academic trajectory based on trend and consistency.
  ///
  /// CLASSIFICATION LOGIC:
  /// - Examines slope for direction (improving/declining)
  /// - Considers volatility for reliability assessment
  /// - Combines into actionable categories
  ///
  /// ACADEMIC SIGNIFICANCE:
  /// Different trajectories require different interventions:
  /// - Improving: Reinforce successful strategies
  /// - Stable High: Maintain habits, explore challenges
  /// - Stable Low: Need intervention and support
  /// - Declining: Urgent investigation required
  /// - Volatile: Address consistency issues first
  PerformanceClassification _classifyPerformance(
      TrendResult trend,
      double stdDev,
      ) {
    const slopeThreshold = 0.05; // Significant change per semester
    const volatilityThreshold = 0.3; // High variability

    if (stdDev > volatilityThreshold) {
      return PerformanceClassification.volatile;
    }

    if (trend.slope > slopeThreshold) {
      return PerformanceClassification.improving;
    } else if (trend.slope < -slopeThreshold) {
      return PerformanceClassification.declining;
    } else {
      // Stable - but is it high or low?
      // Use intercept as proxy for current level
      return trend.intercept >= 3.0
          ? PerformanceClassification.stableHigh
          : PerformanceClassification.stableLow;
    }
  }

  // ===========================================================================
  // PREDICTIVE MODELING
  // ===========================================================================

  /// Predicts future GPA using historical trend with confidence intervals.
  ///
  /// METHODOLOGY:
  /// 1. Projects trend line forward
  /// 2. Calculates confidence intervals based on historical volatility
  /// 3. Generates best/worst case scenarios
  /// 4. Assigns confidence score
  ///
  /// CONFIDENCE SCORING:
  /// - High (>0.8): Strong linear trend, low volatility, many data points
  /// - Medium (0.5-0.8): Moderate trend, some volatility
  /// - Low (<0.5): High volatility, few data points, poor fit
  ///
  /// ETHICAL CONSIDERATIONS:
  /// - Predictions should guide, not dictate
  /// - Always present uncertainty range
  /// - Emphasize that student behavior can change outcomes
  /// - Use for planning, not for limiting opportunities
  ///
  /// [historicalGPAs] - Past semester GPAs
  /// [semestersAhead] - How many semesters to project
  /// Returns: Prediction with confidence intervals
  GPAPrediction predictFutureGPA({
    required List<double> historicalGPAs,
    required int semestersAhead,
    double maxGPA = 4.0,
  }) {
    if (historicalGPAs.isEmpty || semestersAhead < 1) {
      return GPAPrediction.empty();
    }

    final analysis = analyzePerformance(historicalGPAs);

    // Project trend line forward
    final futureIndex = historicalGPAs.length + semestersAhead - 1;
    final predicted = analysis.trendSlope * futureIndex + analysis.trendIntercept;

    // Calculate confidence based on R² and data points
    final confidence = _calculateConfidence(
      rSquared: analysis.rSquared,
      dataPoints: historicalGPAs.length,
      volatility: analysis.standardDeviation,
    );

    // Generate scenarios using volatility
    // Best case: +1.5 standard deviations
    // Worst case: -1.5 standard deviations
    final bestCase = math.min(
      predicted + (1.5 * analysis.standardDeviation),
      maxGPA,
    );

    final worstCase = math.max(
      predicted - (1.5 * analysis.standardDeviation),
      0.0,
    );

    return GPAPrediction(
      predictedGPA: _clamp(predicted, 0.0, maxGPA),
      bestCaseGPA: _clamp(bestCase, 0.0, maxGPA),
      worstCaseGPA: _clamp(worstCase, 0.0, maxGPA),
      confidenceScore: confidence,
      semestersAhead: semestersAhead,
      methodology: 'linear_regression',
      basedOnSemesters: historicalGPAs.length,
    );
  }

  /// Calculates prediction confidence score (0.0 to 1.0).
  ///
  /// FACTORS:
  /// 1. R² (goodness of fit): Higher = more confident
  /// 2. Data points: More = more confident
  /// 3. Volatility: Lower = more confident
  double _calculateConfidence({
    required double rSquared,
    required int dataPoints,
    required double volatility,
  }) {
    // R² contribution (0-0.4 range)
    final rSquaredScore = rSquared * 0.4;

    // Data points contribution (0-0.3 range)
    // Sigmoid function: more points = higher confidence, but diminishing returns
    final dataPointScore = 0.3 * (1 - math.exp(-dataPoints / 4));

    // Volatility contribution (0-0.3 range)
    // Lower volatility = higher confidence
    final volatilityScore = 0.3 * math.max(0, 1 - (volatility / 0.5));

    final total = rSquaredScore + dataPointScore + volatilityScore;

    return _clamp(total, 0.0, 1.0);
  }

  /// Monte Carlo simulation for GPA scenarios.
  ///
  /// WHY MONTE CARLO:
  /// Generates probability distribution of outcomes by running many
  /// random simulations. More sophisticated than simple best/worst case.
  ///
  /// PROCESS:
  /// 1. Model each future semester as random variable
  /// 2. Draw from normal distribution (mean = predicted, std = historical volatility)
  /// 3. Run 10,000 simulations
  /// 4. Calculate percentiles (10th, 50th, 90th)
  ///
  /// WHEN TO USE:
  /// - User wants detailed probability analysis
  /// - Multiple semesters ahead (2+)
  /// - High-stakes decisions (grad school planning)
  List<GPAScenario> runMonteCarloSimulation({
    required double currentGPA,
    required int currentCredits,
    required int futureSemesters,
    required double historicalMean,
    required double historicalStdDev,
    required int creditsPerSemester,
    int simulations = 10000,
    double maxGPA = 4.0,
  }) {
    final random = math.Random();
    final outcomes = <double>[];

    for (int i = 0; i < simulations; i++) {
      double cumulativeGPA = currentGPA;
      int totalCredits = currentCredits;

      // Simulate each future semester
      for (int sem = 0; sem < futureSemesters; sem++) {
        // Generate random semester GPA from normal distribution
        final semesterGPA = _generateNormalRandom(
          random,
          historicalMean,
          historicalStdDev,
        );

        final clampedGPA = _clamp(semesterGPA, 0.0, maxGPA);

        // Update cumulative GPA
        final currentQP = cumulativeGPA * totalCredits;
        final newQP = clampedGPA * creditsPerSemester;
        totalCredits += creditsPerSemester;
        cumulativeGPA = (currentQP + newQP) / totalCredits;
      }

      outcomes.add(cumulativeGPA);
    }

    // Sort outcomes for percentile calculation
    outcomes.sort();

    return [
      GPAScenario(
        label: 'Pessimistic (10th percentile)',
        gpa: outcomes[(simulations * 0.1).toInt()],
        probability: 0.1,
      ),
      GPAScenario(
        label: 'Expected (50th percentile)',
        gpa: outcomes[(simulations * 0.5).toInt()],
        probability: 0.5,
      ),
      GPAScenario(
        label: 'Optimistic (90th percentile)',
        gpa: outcomes[(simulations * 0.9).toInt()],
        probability: 0.9,
      ),
    ];
  }

  /// Generates random number from normal distribution (Box-Muller transform).
  double _generateNormalRandom(math.Random random, double mean, double stdDev) {
    final u1 = random.nextDouble();
    final u2 = random.nextDouble();

    final z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);

    return mean + z * stdDev;
  }

  /// Detects semester-to-semester deltas and flags significant changes.
  ///
  /// Useful for identifying:
  /// - Breakthrough semesters
  /// - Crisis semesters
  /// - Transition impacts
  List<SemesterDelta> analyzeSemesterDeltas(List<double> semesterGPAs) {
    if (semesterGPAs.length < 2) return [];

    final deltas = <SemesterDelta>[];

    for (int i = 1; i < semesterGPAs.length; i++) {
      final delta = semesterGPAs[i] - semesterGPAs[i - 1];
      final significance = _categorizeDelta(delta);

      deltas.add(SemesterDelta(
        fromSemester: i - 1,
        toSemester: i,
        fromGPA: semesterGPAs[i - 1],
        toGPA: semesterGPAs[i],
        change: delta,
        significance: significance,
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

  double _clamp(double value, double min, double max) {
    return math.max(min, math.min(max, value));
  }
}

// =============================================================================
// RESULT DATA CLASSES
// =============================================================================

class PerformanceAnalysis {
  final double meanGPA;
  final double standardDeviation;
  final double trendSlope;
  final double trendIntercept;
  final PerformanceClassification classification;
  final int semesterCount;
  final double highestGPA;
  final double lowestGPA;
  final double rSquared;

  const PerformanceAnalysis({
    required this.meanGPA,
    required this.standardDeviation,
    required this.trendSlope,
    required this.trendIntercept,
    required this.classification,
    required this.semesterCount,
    required this.highestGPA,
    required this.lowestGPA,
    required this.rSquared,
  });

  factory PerformanceAnalysis.empty() {
    return const PerformanceAnalysis(
      meanGPA: 0.0,
      standardDeviation: 0.0,
      trendSlope: 0.0,
      trendIntercept: 0.0,
      classification: PerformanceClassification.insufficient,
      semesterCount: 0,
      highestGPA: 0.0,
      lowestGPA: 0.0,
      rSquared: 0.0,
    );
  }

  /// Coefficient of variation (relative volatility)
  double get coefficientOfVariation =>
      meanGPA > 0 ? standardDeviation / meanGPA : 0.0;

  /// Range of performance
  double get gpaRange => highestGPA - lowestGPA;

  /// Consistency rating
  String get consistencyRating {
    if (standardDeviation < 0.15) return 'Highly Consistent';
    if (standardDeviation < 0.30) return 'Moderately Consistent';
    if (standardDeviation < 0.50) return 'Somewhat Variable';
    return 'Highly Variable';
  }
}

class TrendResult {
  final double slope;
  final double intercept;
  final double rSquared;

  const TrendResult({
    required this.slope,
    required this.intercept,
    required this.rSquared,
  });
}

enum PerformanceClassification {
  improving, // Upward trend
  declining, // Downward trend
  stableHigh, // Consistent high performance
  stableLow, // Consistent low performance
  volatile, // High variability
  insufficient, // Not enough data
}

class GPAPrediction {
  final double predictedGPA;
  final double bestCaseGPA;
  final double worstCaseGPA;
  final double confidenceScore;
  final int semestersAhead;
  final String methodology;
  final int basedOnSemesters;

  const GPAPrediction({
    required this.predictedGPA,
    required this.bestCaseGPA,
    required this.worstCaseGPA,
    required this.confidenceScore,
    required this.semestersAhead,
    required this.methodology,
    required this.basedOnSemesters,
  });

  factory GPAPrediction.empty() {
    return const GPAPrediction(
      predictedGPA: 0.0,
      bestCaseGPA: 0.0,
      worstCaseGPA: 0.0,
      confidenceScore: 0.0,
      semestersAhead: 0,
      methodology: 'none',
      basedOnSemesters: 0,
    );
  }

  double get predictionRange => bestCaseGPA - worstCaseGPA;

  String get confidenceLevel {
    if (confidenceScore >= 0.8) return 'High';
    if (confidenceScore >= 0.5) return 'Medium';
    return 'Low';
  }
}

class GPAScenario {
  final String label;
  final double gpa;
  final double probability;

  const GPAScenario({
    required this.label,
    required this.gpa,
    required this.probability,
  });
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