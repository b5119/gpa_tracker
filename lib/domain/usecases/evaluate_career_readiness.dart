import '../entities/grading_config.dart';
import '../models/career_sector.dart';

/// Evaluate student readiness for career sectors
///
/// WHY ELIGIBILITY VS COMPETITIVENESS MATTERS:
///
/// Example: Investment Banking
/// - Minimum GPA: 3.2 (you can apply)
/// - Competitive GPA: 3.7 (you're a strong candidate)
/// - Target GPA: 3.9 (you're exceptional)
///
/// A student with 3.4 GPA is:
/// ✅ ELIGIBLE (meets minimum)
/// ❌ NOT COMPETITIVE (below 3.7)
///
/// This distinction is critical because:
/// - Students waste time applying to unrealistic opportunities
/// - Advisors need data to guide career planning
/// - Motivation: "You CAN apply, but here's what improves odds"
///
/// PROGRAM-SENSITIVE GPA INTERPRETATION:
///
/// A 3.5 GPA means different things:
/// - Computer Science Bachelor's: Strong (competitive for tech)
/// - Finance Bachelor's: Good (competitive for most roles)
/// - Engineering Master's: Below expectations (often need 3.7+)
/// - Law School Applicant: Below competitive (need 3.7-3.9)
///
/// This use case provides CONTEXT-AWARE career assessment.
class EvaluateCareerReadiness {
  /// Evaluate readiness across all career sectors
  CareerReadinessReport execute({
    required double currentGPA,
    required GradingConfig gradingConfig,
    required List<CareerSector> sectors,
    List<String>? interestedSectorIds,
  }) {
    final sectorEvaluations = <SectorEvaluation>[];

    for (final sector in sectors) {
      final evaluation = _evaluateSector(
        sector: sector,
        currentGPA: currentGPA,
        gradingConfig: gradingConfig,
        isInterested: interestedSectorIds?.contains(sector.id) ?? false,
      );

      sectorEvaluations.add(evaluation);
    }

    // Sort by readiness score (descending)
    sectorEvaluations.sort((a, b) => b.readinessScore.compareTo(a.readinessScore));

    // Categorize opportunities
    final ready = sectorEvaluations
        .where((e) => e.readiness == CareerReadiness.highlyCompetitive ||
        e.readiness == CareerReadiness.competitive)
        .toList();

    final reachable = sectorEvaluations
        .where((e) => e.readiness == CareerReadiness.eligible &&
        e.gapToCompetitive <= 0.5)
        .toList();

    final aspirational = sectorEvaluations
        .where((e) => e.gapToCompetitive > 0.5)
        .toList();

    // Generate overall insights
    final insights = _generateCareerInsights(
      currentGPA: currentGPA,
      ready: ready,
      reachable: reachable,
      totalSectors: sectors.length,
    );

    return CareerReadinessReport(
      currentGPA: currentGPA,
      allSectors: sectorEvaluations,
      readySectors: ready,
      reachableSectors: reachable,
      aspirationalSectors: aspirational,
      overallInsights: insights,
    );
  }

  SectorEvaluation _evaluateSector({
    required CareerSector sector,
    required double currentGPA,
    required GradingConfig gradingConfig,
    required bool isInterested,
  }) {
    // Normalize GPA to sector's scale if needed
    final normalizedGPA = _normalizeGPA(
      currentGPA,
      gradingConfig.maxGPA,
      sector.competitiveGPA > 10 ? 100.0 : 4.0, // Detect percentage vs points
    );

    // Calculate readiness
    final readiness = sector.getReadiness(normalizedGPA);
    final fitScore = sector.calculateFitScore(normalizedGPA);

    // Calculate gaps
    final gapToMinimum = (sector.minimumGPA - normalizedGPA).clamp(0.0, double.infinity);
    final gapToCompetitive = (sector.competitiveGPA - normalizedGPA).clamp(0.0, double.infinity);
    final gapToTarget = (sector.targetGPA - normalizedGPA).clamp(0.0, double.infinity);

    // Determine next milestone
    final nextMilestone = _determineNextMilestone(
      normalizedGPA,
      gapToMinimum,
      gapToCompetitive,
      gapToTarget,
      sector,
    );

    // Calculate readiness score (0-100)
    final readinessScore = _calculateReadinessScore(
      fitScore: fitScore,
      readiness: readiness,
      isInterested: isInterested,
    );

    // Generate specific recommendations
    final recommendations = _generateSectorRecommendations(
      sector: sector,
      readiness: readiness,
      currentGPA: normalizedGPA,
      gapToCompetitive: gapToCompetitive,
    );

    return SectorEvaluation(
      sector: sector,
      readiness: readiness,
      readinessScore: readinessScore,
      fitScore: fitScore,
      gapToMinimum: gapToMinimum,
      gapToCompetitive: gapToCompetitive,
      gapToTarget: gapToTarget,
      nextMilestone: nextMilestone,
      recommendations: recommendations,
      isInterested: isInterested,
    );
  }

  double _normalizeGPA(double gpa, double fromScale, double toScale) {
    if ((fromScale - toScale).abs() < 0.1) return gpa;
    return (gpa / fromScale) * toScale;
  }

  MilestoneInfo _determineNextMilestone(
      double currentGPA,
      double gapToMin,
      double gapToCompetitive,
      double gapToTarget,
      CareerSector sector,
      ) {
    if (gapToMin > 0) {
      return MilestoneInfo(
        name: 'Minimum Eligibility',
        requiredGPA: sector.minimumGPA,
        gap: gapToMin,
        description: 'Meet basic requirements to apply',
      );
    }

    if (gapToCompetitive > 0) {
      return MilestoneInfo(
        name: 'Competitive Threshold',
        requiredGPA: sector.competitiveGPA,
        gap: gapToCompetitive,
        description: 'Become a strong candidate',
      );
    }

    if (gapToTarget > 0) {
      return MilestoneInfo(
        name: 'Target Excellence',
        requiredGPA: sector.targetGPA,
        gap: gapToTarget,
        description: 'Reach top-tier status',
      );
    }

    return MilestoneInfo(
      name: 'Target Achieved',
      requiredGPA: sector.targetGPA,
      gap: 0.0,
      description: 'You meet all GPA requirements',
    );
  }

  double _calculateReadinessScore({
    required double fitScore,
    required CareerReadiness readiness,
    required bool isInterested,
  }) {
    double score = fitScore * 100;

    // Boost for user interest
    if (isInterested) {
      score = (score * 1.2).clamp(0.0, 100.0);
    }

    return score;
  }

  List<String> _generateSectorRecommendations({
    required CareerSector sector,
    required CareerReadiness readiness,
    required double currentGPA,
    required double gapToCompetitive,
  }) {
    final recommendations = <String>[];

    switch (readiness) {
      case CareerReadiness.highlyCompetitive:
        recommendations.add('🌟 Excellent fit! Focus on building ${_getSectorSkills(sector)}');
        recommendations.add('Consider targeting top companies in this sector');
        break;

      case CareerReadiness.competitive:
        recommendations.add('✅ Competitive candidate! Strengthen with relevant experience');
        recommendations.add('Build: ${_getSectorSkills(sector)}');
        break;

      case CareerReadiness.eligible:
        if (gapToCompetitive <= 0.3) {
          recommendations.add('📈 Within reach! Aim for ${sector.competitiveGPA.toStringAsFixed(2)} GPA');
          recommendations.add('Focus on high-credit courses this semester');
        } else {
          recommendations.add('⚠️ Eligible but not competitive yet');
          recommendations.add('Need ${gapToCompetitive.toStringAsFixed(2)} GPA improvement');
        }
        break;

      case CareerReadiness.notReady:
        recommendations.add('🎯 Currently below minimum (${sector.minimumGPA.toStringAsFixed(2)} required)');
        recommendations.add('Consider alternative paths or GPA improvement plan');
        break;
    }

    return recommendations;
  }

  String _getSectorSkills(CareerSector sector) {
    final skillMap = {
      'Investment Banking': 'financial modeling, networking, Excel skills',
      'Management Consulting': 'case interviews, business acumen, presentation skills',
      'Software Engineering': 'coding projects, system design, GitHub portfolio',
      'Data Science': 'ML projects, statistics, Python/R proficiency',
      'Academia': 'research experience, publications, strong letters',
    };

    return skillMap[sector.name] ?? 'relevant skills and experience';
  }

  List<String> _generateCareerInsights({
    required double currentGPA,
    required List<SectorEvaluation> ready,
    required List<SectorEvaluation> reachable,
    required int totalSectors,
  }) {
    final insights = <String>[];

    if (ready.length >= 5) {
      insights.add('🎯 Strong position! You\'re competitive in ${ready.length} sectors');
    } else if (ready.length >= 3) {
      insights.add('✅ Good standing! Competitive in ${ready.length} sectors');
    } else if (reachable.length >= 3) {
      insights.add('📈 Opportunity exists! ${reachable.length} sectors within reach');
    } else {
      insights.add('💪 Focus on GPA improvement to expand opportunities');
    }

    // Best fit sector
    if (ready.isNotEmpty) {
      insights.add('Top match: ${ready.first.sector.name}');
    }

    return insights;
  }
}

/// Career readiness report
class CareerReadinessReport {
  final double currentGPA;
  final List<SectorEvaluation> allSectors;
  final List<SectorEvaluation> readySectors;
  final List<SectorEvaluation> reachableSectors;
  final List<SectorEvaluation> aspirationalSectors;
  final List<String> overallInsights;

  const CareerReadinessReport({
    required this.currentGPA,
    required this.allSectors,
    required this.readySectors,
    required this.reachableSectors,
    required this.aspirationalSectors,
    required this.overallInsights,
  });

  int get totalCompetitiveSectors => readySectors.length;
  int get totalReachableSectors => reachableSectors.length;

  String get overallAssessment {
    if (readySectors.length >= 5) {
      return 'Strong position across multiple sectors';
    } else if (readySectors.length >= 3) {
      return 'Competitive in several sectors';
    } else if (reachableSectors.length >= 3) {
      return 'Multiple sectors within reach';
    } else {
      return 'Focus on improving GPA to expand opportunities';
    }
  }
}

/// Individual sector evaluation
class SectorEvaluation {
  final CareerSector sector;
  final CareerReadiness readiness;
  final double readinessScore; // 0-100
  final double fitScore; // 0.0-1.0
  final double gapToMinimum;
  final double gapToCompetitive;
  final double gapToTarget;
  final MilestoneInfo nextMilestone;
  final List<String> recommendations;
  final bool isInterested;

  const SectorEvaluation({
    required this.sector,
    required this.readiness,
    required this.readinessScore,
    required this.fitScore,
    required this.gapToMinimum,
    required this.gapToCompetitive,
    required this.gapToTarget,
    required this.nextMilestone,
    required this.recommendations,
    required this.isInterested,
  });

  String get readinessLabel {
    switch (readiness) {
      case CareerReadiness.highlyCompetitive:
        return 'Highly Competitive';
      case CareerReadiness.competitive:
        return 'Competitive';
      case CareerReadiness.eligible:
        return 'Eligible';
      case CareerReadiness.notReady:
        return 'Not Ready';
    }
  }
}

class MilestoneInfo {
  final String name;
  final double requiredGPA;
  final double gap;
  final String description;

  const MilestoneInfo({
    required this.name,
    required this.requiredGPA,
    required this.gap,
    required this.description,
  });
}