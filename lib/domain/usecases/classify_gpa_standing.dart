import '../entities/grading_config.dart';

/// Classify GPA into meaningful academic standings
///
/// WHY STANDING IS MORE INTERPRETABLE THAN RAW GPA:
///
/// A GPA of 3.2 means nothing without context:
/// - In US Bachelor's: "Good Standing" (competitive for most careers)
/// - In UK system: Would be ~64% (Upper Second Class Honours)
/// - In Master's program: Below expectations (often requires 3.5+)
/// - For law school: Below competitive threshold (needs 3.7+)
///
/// Academic standing provides:
/// - Immediate interpretation ("Dean's List" vs "3.67")
/// - Eligibility awareness (probation, honors, etc.)
/// - Cross-system comparability
/// - Motivational targets ("I want First Class Honours")
///
/// REGIONAL CLASSIFICATION DIFFERENCES:
///
/// US System:
/// - Dean's List / President's List (3.5-4.0)
/// - Good Standing (3.0-3.5)
/// - Satisfactory (2.0-3.0)
/// - Academic Probation (1.0-2.0)
/// - Academic Dismissal (<1.0)
///
/// UK System:
/// - First Class Honours (70-100%)
/// - Upper Second Class - 2:1 (60-69%)
/// - Lower Second Class - 2:2 (50-59%)
/// - Third Class (40-49%)
/// - Fail (<40%)
///
/// Australian System:
/// - High Distinction (HD): 85-100%
/// - Distinction (D): 75-84%
/// - Credit (C): 65-74%
/// - Pass (P): 50-64%
/// - Fail (F): <50%
///
/// Canadian System:
/// - A+/A (4.0-3.7): Excellent
/// - B (3.3-2.7): Good
/// - C (2.3-1.7): Satisfactory
/// - D (1.3-1.0): Minimal Pass
/// - F (0.0): Fail
class ClassifyGPAStanding {
  /// Classify current GPA into academic standing
  GPAStandingResult execute({
    required double gpa,
    required GradingConfig gradingConfig,
  }) {
    // Get classification from grading config
    final classification = gradingConfig.getClassification(gpa);

    // Calculate distance to next tier
    final nextClassification = _getNextClassification(
      gpa,
      gradingConfig.classifications,
    );

    final distanceToNext = nextClassification != null
        ? nextClassification.minGPA - gpa
        : 0.0;

    // Determine status level
    final statusLevel = _determineStatusLevel(
      classification,
      gradingConfig.classifications,
    );

    // Generate actionable insights
    final insights = _generateInsights(
      gpa,
      classification,
      nextClassification,
      distanceToNext,
      statusLevel,
    );

    return GPAStandingResult(
      currentGPA: gpa,
      classification: classification,
      nextClassification: nextClassification,
      distanceToNext: distanceToNext,
      statusLevel: statusLevel,
      insights: insights,
    );
  }

  /// Get next higher classification
  GPAClassification? _getNextClassification(
    double currentGPA,
    List<GPAClassification> classifications,
  ) {
    // Find classifications above current GPA
    final higherClassifications = classifications
        .where((c) => c.minGPA > currentGPA)
        .toList();

    if (higherClassifications.isEmpty) return null;

    // Return the lowest one above current (immediate next tier)
    higherClassifications.sort((a, b) => a.minGPA.compareTo(b.minGPA));
    return higherClassifications.first;
  }

  /// Determine overall status level
  StandingStatusLevel _determineStatusLevel(
    GPAClassification current,
    List<GPAClassification> allClassifications,
  ) {
    // Sort classifications by minGPA descending
    final sorted = allClassifications.toList()
      ..sort((a, b) => b.minGPA.compareTo(a.minGPA));

    final index = sorted.indexOf(current);
    final total = sorted.length;

    // Top tier
    if (index == 0) return StandingStatusLevel.excellent;

    // Top 2 tiers
    if (index <= 1 && total > 3) return StandingStatusLevel.strong;

    // Middle tiers
    if (index < total - 2) return StandingStatusLevel.satisfactory;

    // Second to last
    if (index == total - 2) return StandingStatusLevel.atRisk;

    // Lowest tier
    return StandingStatusLevel.critical;
  }

  /// Generate actionable insights
  List<String> _generateInsights(
    double gpa,
    GPAClassification current,
    GPAClassification? next,
    double distanceToNext,
    StandingStatusLevel level,
  ) {
    final insights = <String>[];

    // Current standing insight
    insights.add('You are currently in ${current.name}');

    // Next tier insight
    if (next != null) {
      if (distanceToNext <= 0.1) {
        insights.add(
          'You are very close to ${next.name}! '
          'Only ${distanceToNext.toStringAsFixed(2)} points away.',
        );
      } else if (distanceToNext <= 0.3) {
        insights.add(
          'You can reach ${next.name} with consistent performance. '
          '${distanceToNext.toStringAsFixed(2)} points needed.',
        );
      } else {
        insights.add(
          '${next.name} requires ${distanceToNext.toStringAsFixed(2)} more points. '
          'Focus on high-credit courses for maximum impact.',
        );
      }
    } else {
      insights.add(
        'You have achieved the highest classification! Maintain this excellence.',
      );
    }

    // Status-specific insights
    switch (level) {
      case StandingStatusLevel.excellent:
        insights.add(
          'Outstanding academic performance. You qualify for honors and top opportunities.',
        );
        break;

      case StandingStatusLevel.strong:
        insights.add(
          'Strong academic standing. You are competitive for most career paths.',
        );
        break;

      case StandingStatusLevel.satisfactory:
        insights.add(
          'Satisfactory progress. Focus on improving in challenging subjects.',
        );
        break;

      case StandingStatusLevel.atRisk:
        insights.add(
          '⚠️ At-risk status. Consider academic support services and reduced course load.',
        );
        break;

      case StandingStatusLevel.critical:
        insights.add(
          '🚨 Critical status. Immediate intervention required. Contact your academic advisor.',
        );
        break;
    }

    return insights;
  }
}

/// Result of GPA standing classification
class GPAStandingResult {
  final double currentGPA;
  final GPAClassification classification;
  final GPAClassification? nextClassification;
  final double distanceToNext;
  final StandingStatusLevel statusLevel;
  final List<String> insights;

  const GPAStandingResult({
    required this.currentGPA,
    required this.classification,
    this.nextClassification,
    required this.distanceToNext,
    required this.statusLevel,
    required this.insights,
  });

  /// Is student in good academic standing?
  bool get isGoodStanding {
    return statusLevel == StandingStatusLevel.excellent ||
        statusLevel == StandingStatusLevel.strong ||
        statusLevel == StandingStatusLevel.satisfactory;
  }

  /// Requires intervention?
  bool get requiresIntervention {
    return statusLevel == StandingStatusLevel.atRisk ||
        statusLevel == StandingStatusLevel.critical;
  }
}

/// Overall status level for UI display and alerts
enum StandingStatusLevel {
  excellent, // Top tier, honors eligible
  strong, // Good standing, competitive
  satisfactory, // Passing, acceptable
  atRisk, // Below expectations, needs attention
  critical, // Failing, immediate action required
}
