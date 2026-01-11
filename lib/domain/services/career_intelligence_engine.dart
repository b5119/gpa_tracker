// =============================================================================
// CAREER INTELLIGENCE & RECOMMENDATION ENGINE
// =============================================================================
// This module maps academic performance to employment sector opportunities.
//
// WHY THIS EXISTS:
// Students need to understand how their GPA affects career prospects. Different
// sectors have vastly different GPA expectations:
// - Investment Banking: 3.7+ highly preferred
// - Tech/Software: 3.0+ competitive, but skills matter more
// - Government: 2.5-3.0 often sufficient
// - Academia/Research: 3.8+ typically required for top programs
//
// This system:
// 1. Evaluates fit between student GPA and sector requirements
// 2. Identifies realistic career paths
// 3. Provides actionable recommendations
// 4. Calculates GPA targets for desired careers
import 'dart:math' as math;
import '../models/career_sector.dart';

/// Career sector intelligence and academic-to-career mapping service.
///
/// This service bridges academic performance with employment market realities,
/// providing students with data-driven career guidance.
class CareerIntelligenceEngine {
  final List<CareerSector> _sectors;

  /// Creates engine with sector database.
  ///
  /// [sectors] should be loaded from JSON configuration to allow
  /// regional customization without code changes.
  CareerIntelligenceEngine({required List<CareerSector> sectors})
      : _sectors = sectors;

  /// Factory constructor with default US-based sector data.
  ///
  /// SECTOR DATA SOURCES:
  /// - National Association of Colleges and Employers (NACE)
  /// - Industry hiring surveys
  /// - University career center statistics
  /// - Professional association requirements
  ///
  /// NOTE: These are generalizations. Individual companies vary significantly.
  factory CareerIntelligenceEngine.withDefaultSectors() {
    return CareerIntelligenceEngine(sectors: _defaultUSCareerSectors);
  }

  // ===========================================================================
  // CAREER FIT ANALYSIS
  // ===========================================================================

  /// Evaluates student's fit across all career sectors.
  ///
  /// SCORING METHODOLOGY:
  /// For each sector, calculates:
  /// 1. Fit score (0.0-1.0): How well GPA matches requirements
  /// 2. Readiness level: Below minimum / Eligible / Competitive / Target
  /// 3. Gap analysis: GPA needed to reach next tier
  ///
  /// SORTING STRATEGY:
  /// - Primary: Sectors where student is competitive (score > 0.5)
  /// - Secondary: Sectors within reach (score 0.3-0.5)
  /// - Tertiary: All others, sorted by fit score
  ///
  /// [currentGPA] - Student's cumulative GPA
  /// [interestedSectors] - Optional sector IDs to prioritize
  /// Returns: Comprehensive career fit report
  CareerFitReport analyzeCareerFit({
    required double currentGPA,
    List<String>? interestedSectors,
  }) {
    final sectorAnalyses = <SectorAnalysis>[];

    for (final sector in _sectors) {
      final fitScore = sector.calculateFitScore(currentGPA);
      final readiness = sector.getReadiness(currentGPA);
      final gapToCompetitive = math.max(0.0, sector.competitiveGPA - currentGPA);
      final gapToTarget = math.max(0.0, sector.targetGPA - currentGPA);

      final isInterested = interestedSectors?.contains(sector.id) ?? false;

      sectorAnalyses.add(SectorAnalysis(
        sector: sector,
        fitScore: fitScore,
        readiness: readiness,
        gapToCompetitive: gapToCompetitive,
        gapToTarget: gapToTarget,
        isInterested: isInterested,
      ));
    }

    // Sort by fit score (descending)
    sectorAnalyses.sort((a, b) => b.fitScore.compareTo(a.fitScore));

    // Categorize opportunities
    final readySectors = sectorAnalyses
        .where((s) => s.readiness == CareerReadiness.competitive ||
        s.readiness == CareerReadiness.highlyCompetitive)
        .toList();

    final reachableSectors = sectorAnalyses
        .where((s) => s.readiness == CareerReadiness.eligible && s.gapToCompetitive <= 0.5)
        .toList();

    final aspirationalSectors = sectorAnalyses
        .where((s) => s.gapToCompetitive > 0.5)
        .toList();

    return CareerFitReport(
      currentGPA: currentGPA,
      allSectors: sectorAnalyses,
      readySectors: readySectors,
      reachableSectors: reachableSectors,
      aspirationalSectors: aspirationalSectors,
      topRecommendations: _generateTopRecommendations(sectorAnalyses),
    );
  }

  /// Generates top 5 sector recommendations based on fit and opportunity.
  List<SectorAnalysis> _generateTopRecommendations(
      List<SectorAnalysis> analyses,
      ) {
    // Prioritize:
    // 1. Interested sectors where student is competitive
    // 2. High-fit sectors (score > 0.6)
    // 3. Sectors within reach (gap < 0.3)

    final scored = analyses.map((a) {
      double score = a.fitScore;

      // Boost interested sectors
      if (a.isInterested) score += 0.2;

      // Boost sectors within reach
      if (a.gapToCompetitive <= 0.3) score += 0.1;

      return MapEntry(a, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(5).map((e) => e.key).toList();
  }

  // ===========================================================================
  // TARGET GPA CALCULATION
  // ===========================================================================

  /// Calculates required GPA to become competitive in target sector.
  ///
  /// STRATEGIC GUIDANCE:
  /// - If already competitive: Show path to target tier
  /// - If below competitive: Show requirements to reach competitive
  /// - If far below minimum: Recommend achievable alternative sectors
  ///
  /// [targetSectorId] - Desired career sector
  /// [currentGPA] - Current cumulative GPA
  /// [remainingCredits] - Credits left to earn
  /// [currentCredits] - Credits already earned
  /// Returns: Detailed path to target GPA
  TargetGPAAnalysis calculateTargetGPA({
    required String targetSectorId,
    required double currentGPA,
    required int remainingCredits,
    required int currentCredits,
  }) {
    final sector = _sectors.firstWhere(
          (s) => s.id == targetSectorId,
      orElse: () => throw ArgumentError('Sector not found: $targetSectorId'),
    );

    final currentReadiness = sector.getReadiness(currentGPA);

    // Determine target tier based on current position
    double targetTier;
    String targetTierName;

    if (currentReadiness == CareerReadiness.highlyCompetitive) {
      // Already at target, maintain
      targetTier = sector.targetGPA;
      targetTierName = 'Maintain Target Tier';
    } else if (currentReadiness == CareerReadiness.competitive) {
      // Push to target tier
      targetTier = sector.targetGPA;
      targetTierName = 'Reach Target Tier';
    } else {
      // First reach competitive tier
      targetTier = sector.competitiveGPA;
      targetTierName = 'Reach Competitive Tier';
    }

    // Calculate required semester GPA
    final currentQualityPoints = currentGPA * currentCredits;
    final targetQualityPoints = targetTier * (currentCredits + remainingCredits);
    final requiredQualityPoints = targetQualityPoints - currentQualityPoints;
    final requiredGPA = remainingCredits > 0
        ? requiredQualityPoints / remainingCredits
        : 0.0;

    final isAchievable = requiredGPA <= 4.0 && requiredGPA >= 0.0;

    // Generate recommendations
    final recommendations = _generateStrategicRecommendations(
      sector: sector,
      currentGPA: currentGPA,
      targetGPA: targetTier,
      requiredGPA: requiredGPA,
      isAchievable: isAchievable,
    );

    return TargetGPAAnalysis(
      sector: sector,
      currentGPA: currentGPA,
      currentReadiness: currentReadiness,
      targetTier: targetTier,
      targetTierName: targetTierName,
      requiredGPA: requiredGPA,
      isAchievable: isAchievable,
      remainingCredits: remainingCredits,
      recommendations: recommendations,
    );
  }

  /// Generates strategic academic recommendations.
  List<String> _generateStrategicRecommendations({
    required CareerSector sector,
    required double currentGPA,
    required double targetGPA,
    required double requiredGPA,
    required bool isAchievable,
  }) {
    final recommendations = <String>[];

    if (!isAchievable) {
      recommendations.add(
        'Target GPA of ${targetGPA.toStringAsFixed(2)} is not achievable with remaining credits',
      );
      recommendations.add(
        'Consider these alternatives: explore related sectors with lower GPA requirements, '
            'or pursue additional certifications and skills to compensate',
      );

      // Find reachable alternative sectors
      final alternatives = _sectors
          .where((s) => s.category == sector.category && s.competitiveGPA <= currentGPA + 0.5)
          .take(3)
          .map((s) => s.name)
          .toList();

      if (alternatives.isNotEmpty) {
        recommendations.add(
          'Reachable alternatives in ${sector.category}: ${alternatives.join(", ")}',
        );
      }
    } else {
      if (requiredGPA >= 3.8) {
        recommendations.add(
          'Requires near-perfect performance (${requiredGPA.toStringAsFixed(2)} GPA). '
              'Focus on: advanced courses, research opportunities, and strong relationships with professors',
        );
      } else if (requiredGPA >= 3.5) {
        recommendations.add(
          'Challenging but achievable (${requiredGPA.toStringAsFixed(2)} GPA needed). '
              'Strategies: prioritize high-credit core courses, seek tutoring for difficult subjects',
        );
      } else if (requiredGPA >= 3.0) {
        recommendations.add(
          'Realistic goal (${requiredGPA.toStringAsFixed(2)} GPA needed). '
              'Stay consistent with study habits and seek help early when struggling',
        );
      } else {
        recommendations.add(
          'Highly achievable (${requiredGPA.toStringAsFixed(2)} GPA needed). '
              'Maintain good habits to secure this career path',
        );
      }

      // Course selection advice
      if (requiredGPA >= 3.5) {
        recommendations.add(
          'Course strategy: Balance challenging courses with areas of strength. '
              'Consider pass/fail options for exploratory courses',
        );
      }

      // Beyond GPA advice
      recommendations.add(
        'Remember: For ${sector.name}, also build: ${_getSectorSpecificSkills(sector)}',
      );
    }

    return recommendations;
  }

  String _getSectorSpecificSkills(CareerSector sector) {
    // Sector-specific skill recommendations
    final skillMap = {
      'Investment Banking': 'financial modeling skills, Excel proficiency, networking',
      'Consulting': 'case interview preparation, business acumen, communication skills',
      'Software Engineering': 'coding projects, GitHub portfolio, system design knowledge',
      'Academia': 'research publications, conference presentations, graduate exam scores',
      'Government': 'internship experience, security clearance eligibility, public service commitment',
    };

    return skillMap[sector.name] ?? 'relevant skills, internships, and professional networking';
  }

  // ===========================================================================
  // SECTOR COMPARISON
  // ===========================================================================

  /// Compares multiple career sectors side-by-side.
  ///
  /// Useful for students deciding between career paths.
  SectorComparison compareSectors({
    required List<String> sectorIds,
    required double currentGPA,
  }) {
    final sectors = sectorIds
        .map((id) => _sectors.firstWhere((s) => s.id == id))
        .toList();

    final comparisons = sectors.map((sector) {
      return SectorComparisonItem(
        sector: sector,
        fitScore: sector.calculateFitScore(currentGPA),
        readiness: sector.getReadiness(currentGPA),
        gapToCompetitive: math.max(0.0, sector.competitiveGPA - currentGPA),
        relativeDifficulty: _calculateRelativeDifficulty(sector, currentGPA),
      );
    }).toList();

    // Sort by fit score
    comparisons.sort((a, b) => b.fitScore.compareTo(a.fitScore));

    return SectorComparison(
      currentGPA: currentGPA,
      sectors: comparisons,
      recommendation: _getBestFitFromComparison(comparisons),
    );
  }

  String _calculateRelativeDifficulty(CareerSector sector, double currentGPA) {
    final gap = sector.competitiveGPA - currentGPA;

    if (currentGPA >= sector.targetGPA) return 'Already Exceeded';
    if (gap <= 0) return 'Already Competitive';
    if (gap <= 0.2) return 'Very Reachable';
    if (gap <= 0.5) return 'Reachable';
    if (gap <= 1.0) return 'Challenging';
    return 'Very Challenging';
  }

  String _getBestFitFromComparison(List<SectorComparisonItem> comparisons) {
    if (comparisons.isEmpty) return 'No sectors to compare';

    final best = comparisons.first;

    if (best.readiness == CareerReadiness.highlyCompetitive) {
      return '${best.sector.name} is your strongest fit - you exceed target requirements';
    } else if (best.readiness == CareerReadiness.competitive) {
      return '${best.sector.name} is competitive for you - focus on building sector-specific skills';
    } else if (best.gapToCompetitive <= 0.3) {
      return '${best.sector.name} is within reach - aim for ${best.sector.competitiveGPA.toStringAsFixed(2)} GPA';
    } else {
      return 'Consider expanding your options - current GPA requires significant improvement for listed sectors';
    }
  }
}

// =============================================================================
// DEFAULT SECTOR DATABASE (US-BASED)
// =============================================================================

final _defaultUSCareerSectors = [
  CareerSector(
    id: 'investment-banking',
    name: 'Investment Banking',
    category: 'Finance',
    minimumGPA: 3.2,
    competitiveGPA: 3.7,
    targetGPA: 3.9,
    description: 'Highly selective bulge bracket and boutique investment banks',
    typicalRoles: const ['Analyst', 'Associate', 'M&A Specialist'],
    region: 'US',
  ),
  CareerSector(
    id: 'management-consulting',
    name: 'Management Consulting',
    category: 'Consulting',
    minimumGPA: 3.3,
    competitiveGPA: 3.6,
    targetGPA: 3.8,
    description: 'Top-tier consulting firms (MBB and similar)',
    typicalRoles: const ['Analyst', 'Consultant', 'Strategy Associate'],
    region: 'US',
  ),
  CareerSector(
    id: 'software-engineering',
    name: 'Software Engineering',
    category: 'Technology',
    minimumGPA: 2.7,
    competitiveGPA: 3.2,
    targetGPA: 3.7,
    description: 'Tech companies (FAANG and startups) - skills matter most',
    typicalRoles: const ['Software Engineer', 'Full Stack Developer', 'Backend Engineer'],
    region: 'US',
  ),
  CareerSector(
    id: 'data-science',
    name: 'Data Science & Analytics',
    category: 'Technology',
    minimumGPA: 3.0,
    competitiveGPA: 3.4,
    targetGPA: 3.7,
    description: 'Analytics and data science roles across industries',
    typicalRoles: const ['Data Scientist', 'ML Engineer', 'Analytics Manager'],
    region: 'US',
  ),
  CareerSector(
    id: 'accounting',
    name: 'Public Accounting',
    category: 'Finance',
    minimumGPA: 3.0,
    competitiveGPA: 3.4,
    targetGPA: 3.6,
    description: 'Big 4 and regional accounting firms',
    typicalRoles: const ['Staff Accountant', 'Audit Associate', 'Tax Consultant'],
    region: 'US',
  ),
  CareerSector(
    id: 'federal-government',
    name: 'Federal Government',
    category: 'Public Sector',
    minimumGPA: 2.5,
    competitiveGPA: 3.0,
    targetGPA: 3.5,
    description: 'Federal agencies and civil service positions',
    typicalRoles: const ['Policy Analyst', 'Program Manager', 'Research Specialist'],
    region: 'US',
  ),
  CareerSector(
    id: 'academia-phd',
    name: 'Academic Research (PhD Track)',
    category: 'Academia',
    minimumGPA: 3.5,
    competitiveGPA: 3.7,
    targetGPA: 3.9,
    description: 'PhD programs and research positions at top universities',
    typicalRoles: const ['PhD Candidate', 'Research Assistant', 'Postdoc'],
    region: 'US',
  ),
  CareerSector(
    id: 'law-school',
    name: 'Law School (T14)',
    category: 'Graduate School',
    minimumGPA: 3.4,
    competitiveGPA: 3.7,
    targetGPA: 3.9,
    description: 'Top 14 law schools - highly selective',
    typicalRoles: const ['Law Student', 'Legal Intern', 'Associate Attorney'],
    region: 'US',
  ),
  CareerSector(
    id: 'healthcare-administration',
    name: 'Healthcare Administration',
    category: 'Healthcare',
    minimumGPA: 2.8,
    competitiveGPA: 3.2,
    targetGPA: 3.6,
    description: 'Hospital and healthcare system management',
    typicalRoles: const ['Healthcare Administrator', 'Operations Manager', 'Program Director'],
    region: 'US',
  ),
  CareerSector(
    id: 'marketing-brand',
    name: 'Marketing & Brand Management',
    category: 'Business',
    minimumGPA: 2.7,
    competitiveGPA: 3.0,
    targetGPA: 3.5,
    description: 'Marketing roles in consumer goods and agencies',
    typicalRoles: const ['Brand Manager', 'Marketing Analyst', 'Digital Marketing Specialist'],
    region: 'US',
  ),
];

// =============================================================================
// RESULT DATA CLASSES
// =============================================================================

class CareerFitReport {
  final double currentGPA;
  final List<SectorAnalysis> allSectors;
  final List<SectorAnalysis> readySectors;
  final List<SectorAnalysis> reachableSectors;
  final List<SectorAnalysis> aspirationalSectors;
  final List<SectorAnalysis> topRecommendations;

  const CareerFitReport({
    required this.currentGPA,
    required this.allSectors,
    required this.readySectors,
    required this.reachableSectors,
    required this.aspirationalSectors,
    required this.topRecommendations,
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

class SectorAnalysis {
  final CareerSector sector;
  final double fitScore;
  final CareerReadiness readiness;
  final double gapToCompetitive;
  final double gapToTarget;
  final bool isInterested;

  const SectorAnalysis({
    required this.sector,
    required this.fitScore,
    required this.readiness,
    required this.gapToCompetitive,
    required this.gapToTarget,
    required this.isInterested,
  });

  String get fitLevel {
    if (fitScore >= 0.8) return 'Excellent Fit';
    if (fitScore >= 0.6) return 'Good Fit';
    if (fitScore >= 0.4) return 'Moderate Fit';
    if (fitScore >= 0.2) return 'Weak Fit';
    return 'Poor Fit';
  }
}

class TargetGPAAnalysis {
  final CareerSector sector;
  final double currentGPA;
  final CareerReadiness currentReadiness;
  final double targetTier;
  final String targetTierName;
  final double requiredGPA;
  final bool isAchievable;
  final int remainingCredits;
  final List<String> recommendations;

  const TargetGPAAnalysis({
    required this.sector,
    required this.currentGPA,
    required this.currentReadiness,
    required this.targetTier,
    required this.targetTierName,
    required this.requiredGPA,
    required this.isAchievable,
    required this.remainingCredits,
    required this.recommendations,
  });

  String get difficultyAssessment {
    if (!isAchievable) return 'Not Achievable';
    if (requiredGPA >= 3.9) return 'Extremely Difficult';
    if (requiredGPA >= 3.7) return 'Very Difficult';
    if (requiredGPA >= 3.4) return 'Challenging';
    if (requiredGPA >= 3.0) return 'Moderate';
    return 'Achievable';
  }
}

class SectorComparison {
  final double currentGPA;
  final List<SectorComparisonItem> sectors;
  final String recommendation;

  const SectorComparison({
    required this.currentGPA,
    required this.sectors,
    required this.recommendation,
  });
}

class SectorComparisonItem {
  final CareerSector sector;
  final double fitScore;
  final CareerReadiness readiness;
  final double gapToCompetitive;
  final String relativeDifficulty;

  const SectorComparisonItem({
    required this.sector,
    required this.fitScore,
    required this.readiness,
    required this.gapToCompetitive,
    required this.relativeDifficulty,
  });
}