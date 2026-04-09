import 'dart:math' as math;
import '../entities/grading_config.dart';
import 'analyze_gpa_trend.dart';

/// Time-aware GPA prediction with remaining semester context
///
/// WHY TIME-AWARENESS IS ESSENTIAL:
///
/// Prediction WITHOUT time context:
/// "Your GPA might be 3.6" ← Useless without knowing WHEN
///
/// Prediction WITH time context:
/// "Based on your trend and 4 remaining semesters, you'll likely graduate
///  with 3.6 GPA (range: 3.4-3.8, 75% confidence)" ← Actionable
///
/// Time-aware prediction enables:
/// - Realistic goal setting ("Can I reach 3.7 by graduation?")
/// - Career planning ("Will I qualify for grad school?")
/// - Risk assessment ("Am I on track for honors?")
/// - Intervention timing ("How urgent is improvement?")
///
/// PREDICTION METHODOLOGY:
///
/// 1. Linear Projection:
///    - Extends historical trend forward
///    - Simple, interpretable
///    - Good for stable trends
///    - Poor for volatile performance
///
/// 2. Confidence Scoring:
///    - Based on R² (trend fit quality)
///    - Based on data points (more = better)
///    - Based on volatility (less = better)
///    - Outputs: High/Medium/Low confidence
///
/// 3. Scenario Generation:
///    - Best case: +1.5σ from projection
///    - Expected: Trend line projection
///    - Worst case: -1.5σ from projection
///    - Bounded by grading scale
///
/// LIMITATIONS (ETHICAL DISCLOSURE):
/// - Assumes consistent effort (not guaranteed)
/// - Ignores external factors (life events, course difficulty)
/// - Based on small dataset (typical 4-8 semesters)
/// - Not deterministic (student agency matters)
///
/// ETHICAL CONSIDERATIONS:
/// - Predictions should guide, not limit
/// - Always emphasize student control
/// - Present as probability, not destiny
/// - Include actionable recommendations
class PredictFutureGPA {
  /// Predict final GPA with time awareness
  PredictionResult execute({
    required List<double> historicalGPAs,
    required double currentGPA,
    required int remainingSemesters,
    required int currentCredits,
    required int totalCreditsRequired,
    required GradingConfig gradingConfig,
  }) {
    if (historicalGPAs.isEmpty || remainingSemesters < 1) {
      return PredictionResult.insufficient();
    }

    // Analyze historical trend
    final trendAnalysis = AnalyzeGPATrend().execute(
      semesterGPAs: historicalGPAs,
    );

    // Project trend forward
    final futureIndex = historicalGPAs.length + remainingSemesters - 1;
    final projectedGPA =
        (trendAnalysis.trendSlope * futureIndex + trendAnalysis.trendIntercept)
            .clamp(gradingConfig.minGPA, gradingConfig.maxGPA);

    // Calculate confidence
    final confidence = _calculateConfidence(
      rSquared: trendAnalysis.rSquared,
      dataPoints: historicalGPAs.length,
      volatility: trendAnalysis.standardDeviation,
    );

    // Generate scenarios using volatility
    final bestCase = (projectedGPA + (1.5 * trendAnalysis.standardDeviation))
        .clamp(gradingConfig.minGPA, gradingConfig.maxGPA);

    final worstCase = (projectedGPA - (1.5 * trendAnalysis.standardDeviation))
        .clamp(gradingConfig.minGPA, gradingConfig.maxGPA);

    // Calculate credit-weighted impact
    final creditsRemaining = totalCreditsRequired - currentCredits;
    final impactFactor = creditsRemaining / totalCreditsRequired;

    // Determine risk flags
    final riskFlags = _assessRisks(
      currentGPA: currentGPA,
      projectedGPA: projectedGPA,
      trend: trendAnalysis.classification,
      volatility: trendAnalysis.standardDeviation,
      remainingSemesters: remainingSemesters,
    );

    // Generate recommendations
    final recommendations = _generateRecommendations(
      currentGPA: currentGPA,
      projectedGPA: projectedGPA,
      bestCase: bestCase,
      worstCase: worstCase,
      trend: trendAnalysis.classification,
      remainingSemesters: remainingSemesters,
      impactFactor: impactFactor,
    );

    return PredictionResult(
      projectedFinalGPA: projectedGPA,
      bestCaseGPA: bestCase,
      worstCaseGPA: worstCase,
      confidenceLevel: confidence,
      confidenceScore: _getConfidenceScore(confidence),
      remainingSemesters: remainingSemesters,
      impactFactor: impactFactor,
      riskFlags: riskFlags,
      recommendations: recommendations,
      methodology: 'Linear regression with confidence intervals',
      basedOnSemesters: historicalGPAs.length,
    );
  }

  ConfidenceLevel _calculateConfidence({
    required double rSquared,
    required int dataPoints,
    required double volatility,
  }) {
    // R² contribution (0-40%)
    final rSquaredScore = rSquared * 0.4;

    // Data points contribution (0-30%)
    final dataPointScore = 0.3 * (1 - math.exp(-dataPoints / 4));

    // Volatility contribution (0-30%)
    final volatilityScore = 0.3 * math.max(0, 1 - (volatility / 0.5));

    final totalScore = rSquaredScore + dataPointScore + volatilityScore;

    if (totalScore >= 0.7) return ConfidenceLevel.high;
    if (totalScore >= 0.4) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  double _getConfidenceScore(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 0.85;
      case ConfidenceLevel.medium:
        return 0.65;
      case ConfidenceLevel.low:
        return 0.40;
    }
  }

  List<String> _assessRisks({
    required double currentGPA,
    required double projectedGPA,
    required TrendClassification trend,
    required double volatility,
    required int remainingSemesters,
  }) {
    final risks = <String>[];

    // Declining trend risk
    if (trend == TrendClassification.declining) {
      risks.add('⚠️ Declining trend detected - intervention recommended');
    }

    // High volatility risk
    if (volatility > 0.3) {
      risks.add('⚠️ Inconsistent performance - focus on stability');
    }

    // Low projected GPA risk
    if (projectedGPA < 2.0) {
      risks.add('🚨 Projected GPA below good standing - urgent action needed');
    } else if (projectedGPA < 2.5) {
      risks.add('⚠️ Projected GPA may limit opportunities');
    }

    // Limited time risk
    if (remainingSemesters <= 2 && currentGPA < 3.0) {
      risks.add('⏰ Limited time to improve GPA significantly');
    }

    return risks;
  }

  List<String> _generateRecommendations({
    required double currentGPA,
    required double projectedGPA,
    required double bestCase,
    required double worstCase,
    required TrendClassification trend,
    required int remainingSemesters,
    required double impactFactor,
  }) {
    final recommendations = <String>[];

    // Trend-based recommendations
    if (trend == TrendClassification.improving) {
      recommendations.add(
        '✅ Continue current strategies - your approach is working well',
      );
    } else if (trend == TrendClassification.declining) {
      recommendations.add(
        '🔄 Review study habits and seek academic support immediately',
      );
    }

    // Impact-based recommendations
    if (impactFactor > 0.4) {
      recommendations.add(
        '💡 You have significant opportunity to improve (${(impactFactor * 100).toStringAsFixed(0)}% of credits remaining)',
      );
      recommendations.add(
        '📚 Focus on high-credit courses for maximum GPA impact',
      );
    } else if (impactFactor < 0.2) {
      recommendations.add(
        '⏰ Limited credits remain - maintain current performance',
      );
    }

    // Scenario-based recommendations
    final range = bestCase - worstCase;
    if (range > 0.5) {
      recommendations.add(
        '🎯 Wide outcome range - consistency is key to reaching best case',
      );
    }

    // Specific actions
    if (projectedGPA < 3.0 && remainingSemesters >= 3) {
      recommendations.add(
        '📋 Consider: tutoring, reduced course load, or retaking low grades',
      );
    }

    return recommendations;
  }
}

/// Prediction result with full context
class PredictionResult {
  final double projectedFinalGPA;
  final double bestCaseGPA;
  final double worstCaseGPA;
  final ConfidenceLevel confidenceLevel;
  final double confidenceScore;
  final int remainingSemesters;
  final double impactFactor; // % of total credits remaining
  final List<String> riskFlags;
  final List<String> recommendations;
  final String methodology;
  final int basedOnSemesters;

  const PredictionResult({
    required this.projectedFinalGPA,
    required this.bestCaseGPA,
    required this.worstCaseGPA,
    required this.confidenceLevel,
    required this.confidenceScore,
    required this.remainingSemesters,
    required this.impactFactor,
    required this.riskFlags,
    required this.recommendations,
    required this.methodology,
    required this.basedOnSemesters,
  });

  factory PredictionResult.insufficient() {
    return const PredictionResult(
      projectedFinalGPA: 0.0,
      bestCaseGPA: 0.0,
      worstCaseGPA: 0.0,
      confidenceLevel: ConfidenceLevel.low,
      confidenceScore: 0.0,
      remainingSemesters: 0,
      impactFactor: 0.0,
      riskFlags: ['Insufficient data for prediction'],
      recommendations: ['Complete more semesters to enable predictions'],
      methodology: 'N/A',
      basedOnSemesters: 0,
    );
  }

  double get predictionRange => bestCaseGPA - worstCaseGPA;
  bool get hasHighRisk => riskFlags.any((f) => f.contains('🚨'));

  bool get isReliable =>
      confidenceLevel == ConfidenceLevel.high && predictionRange <= 0.5;
}

enum ConfidenceLevel {
  high, // 70%+ confidence
  medium, // 40-70% confidence
  low, // <40% confidence
}
