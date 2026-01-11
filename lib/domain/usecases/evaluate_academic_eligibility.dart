import '../models/student.dart';
import '../entities/grading_config.dart';

/// Evaluate academic eligibility for graduation, honors, and programs
///
/// ELIGIBILITY CHECKS:
///
/// 1. Graduation Eligibility:
///    - Minimum credits earned
///    - Minimum GPA requirement
///    - Major requirements complete
///
/// 2. Honors Eligibility:
///    - Cum Laude: 3.5+ GPA
///    - Magna Cum Laude: 3.7+ GPA
///    - Summa Cum Laude: 3.9+ GPA
///
/// 3. Dean's List Eligibility:
///    - Semester GPA 3.5+ (typically)
///    - Full-time enrollment
///
/// 4. Graduate School Readiness:
///    - Master's: 3.0+ typically
///    - PhD: 3.5+ typically
///    - Professional (Law/Med): 3.7+ typically
class EvaluateAcademicEligibility {
  /// Evaluate all eligibility criteria
  EligibilityReport execute({
    required Student student,
    required double currentGPA,
    required int earnedCredits,
    required GradingConfig gradingConfig,
  }) {
    // Graduation eligibility
    final graduationCheck = _checkGraduationEligibility(
      earnedCredits: earnedCredits,
      requiredCredits: student.totalCreditsRequired,
      currentGPA: currentGPA,
      gradingConfig: gradingConfig,
    );

    // Honors eligibility
    final honorsCheck = _checkHonorsEligibility(
      currentGPA: currentGPA,
      programType: student.programType,
    );

    // Graduate school readiness
    final gradSchoolCheck = _checkGraduateSchoolReadiness(
      currentGPA: currentGPA,
      programType: student.programType,
    );

    // Dean's List status
    final deansListCheck = _checkDeansListEligibility(
      currentGPA: currentGPA,
      classification: gradingConfig.getClassification(currentGPA),
    );

    return EligibilityReport(
      graduationEligibility: graduationCheck,
      honorsEligibility: honorsCheck,
      graduateSchoolReadiness: gradSchoolCheck,
      deansListEligibility: deansListCheck,
    );
  }

  GraduationEligibility _checkGraduationEligibility({
    required int earnedCredits,
    required int requiredCredits,
    required double currentGPA,
    required GradingConfig gradingConfig,
  }) {
    final minimumGPA = gradingConfig.maxGPA * 0.5; // Typically 2.0 on 4.0 scale

    final meetsCredits = earnedCredits >= requiredCredits;
    final meetsGPA = currentGPA >= minimumGPA;
    final isEligible = meetsCredits && meetsGPA;

    final creditProgress = earnedCredits / requiredCredits;
    final remainingCredits = (requiredCredits - earnedCredits).clamp(0, requiredCredits);

    String status;
    if (isEligible) {
      status = '✅ Eligible to graduate!';
    } else if (creditProgress >= 0.9) {
      status = '📚 Almost there! $remainingCredits credits remaining';
    } else if (creditProgress >= 0.75) {
      status = '📈 On track - ${(creditProgress * 100).toStringAsFixed(0)}% complete';
    } else {
      status = '🎯 ${(creditProgress * 100).toStringAsFixed(0)}% complete';
    }

    final issues = <String>[];
    if (!meetsCredits) {
      issues.add('Need $remainingCredits more credits');
    }
    if (!meetsGPA) {
      final gapToMinimum = minimumGPA - currentGPA;
      issues.add('GPA below minimum (need ${gapToMinimum.toStringAsFixed(2)} improvement)');
    }

    return GraduationEligibility(
      isEligible: isEligible,
      meetsCredits: meetsCredits,
      meetsGPA: meetsGPA,
      creditProgress: creditProgress,
      remainingCredits: remainingCredits,
      status: status,
      issues: issues,
    );
  }

  HonorsEligibility _checkHonorsEligibility({
    required double currentGPA,
    required ProgramType programType,
  }) {
    // Different thresholds for different program types
    final thresholds = _getHonorsThresholds(programType);

    HonorsLevel? level;
    if (currentGPA >= thresholds.summa) {
      level = HonorsLevel.summaCumLaude;
    } else if (currentGPA >= thresholds.magna) {
      level = HonorsLevel.magnaCumLaude;
    } else if (currentGPA >= thresholds.cum) {
      level = HonorsLevel.cumLaude;
    }

    final isEligible = level != null;

    // Calculate gap to next level
    double? gapToNext;
    String? nextLevel;

    if (level == null) {
      gapToNext = thresholds.cum - currentGPA;
      nextLevel = 'Cum Laude';
    } else if (level == HonorsLevel.cumLaude) {
      gapToNext = thresholds.magna - currentGPA;
      nextLevel = 'Magna Cum Laude';
    } else if (level == HonorsLevel.magnaCumLaude) {
      gapToNext = thresholds.summa - currentGPA;
      nextLevel = 'Summa Cum Laude';
    }

    return HonorsEligibility(
      isEligible: isEligible,
      level: level,
      nextLevel: nextLevel,
      gapToNext: gapToNext,
    );
  }

  _HonorsThresholds _getHonorsThresholds(ProgramType programType) {
    switch (programType) {
      case ProgramType.bachelors:
      case ProgramType.honours:
        return const _HonorsThresholds(
          cum: 3.5,
          magna: 3.7,
          summa: 3.9,
        );

      case ProgramType.masters:
        return const _HonorsThresholds(
          cum: 3.7,
          magna: 3.85,
          summa: 3.95,
        );

      default:
        return const _HonorsThresholds(
          cum: 3.5,
          magna: 3.7,
          summa: 3.9,
        );
    }
  }

  GraduateSchoolReadiness _checkGraduateSchoolReadiness({
    required double currentGPA,
    required ProgramType programType,
  }) {
    // Only relevant for Bachelor's students
    if (programType != ProgramType.bachelors &&
        programType != ProgramType.honours) {
      return const GraduateSchoolReadiness(
        isRelevant: false,
        mastersProgramsReady: false,
        phdProgramsReady: false,
        professionalSchoolReady: false,
      );
    }

    final mastersReady = currentGPA >= 3.0;
    final phdReady = currentGPA >= 3.5;
    final professionalReady = currentGPA >= 3.7;

    return GraduateSchoolReadiness(
      isRelevant: true,
      mastersProgramsReady: mastersReady,
      phdProgramsReady: phdReady,
      professionalSchoolReady: professionalReady,
      currentGPA: currentGPA,
    );
  }

  DeansListEligibility _checkDeansListEligibility({
    required double currentGPA,
    required classification,
  }) {
    // Typically Dean's List is 3.5+ on semester or cumulative basis
    final threshold = 3.5;
    final isEligible = currentGPA >= threshold;
    final gap = isEligible ? 0.0 : threshold - currentGPA;

    return DeansListEligibility(
      isEligible: isEligible,
      threshold: threshold,
      gap: gap,
    );
  }
}

class _HonorsThresholds {
  final double cum;
  final double magna;
  final double summa;

  const _HonorsThresholds({
    required this.cum,
    required this.magna,
    required this.summa,
  });
}

/// Complete eligibility report
class EligibilityReport {
  final GraduationEligibility graduationEligibility;
  final HonorsEligibility honorsEligibility;
  final GraduateSchoolReadiness graduateSchoolReadiness;
  final DeansListEligibility deansListEligibility;

  const EligibilityReport({
    required this.graduationEligibility,
    required this.honorsEligibility,
    required this.graduateSchoolReadiness,
    required this.deansListEligibility,
  });

  List<String> get allAchievements {
    final achievements = <String>[];

    if (graduationEligibility.isEligible) {
      achievements.add('✅ Graduation Eligible');
    }

    if (honorsEligibility.isEligible) {
      achievements.add('🎓 ${honorsEligibility.level!.displayName}');
    }

    if (deansListEligibility.isEligible) {
      achievements.add('🌟 Dean\'s List');
    }

    return achievements;
  }
}

class GraduationEligibility {
  final bool isEligible;
  final bool meetsCredits;
  final bool meetsGPA;
  final double creditProgress; // 0.0-1.0
  final int remainingCredits;
  final String status;
  final List<String> issues;

  const GraduationEligibility({
    required this.isEligible,
    required this.meetsCredits,
    required this.meetsGPA,
    required this.creditProgress,
    required this.remainingCredits,
    required this.status,
    required this.issues,
  });
}

class HonorsEligibility {
  final bool isEligible;
  final HonorsLevel? level;
  final String? nextLevel;
  final double? gapToNext;

  const HonorsEligibility({
    required this.isEligible,
    this.level,
    this.nextLevel,
    this.gapToNext,
  });
}

enum HonorsLevel {
  cumLaude,
  magnaCumLaude,
  summaCumLaude,
}

extension HonorsLevelExtension on HonorsLevel {
  String get displayName {
    switch (this) {
      case HonorsLevel.cumLaude:
        return 'Cum Laude';
      case HonorsLevel.magnaCumLaude:
        return 'Magna Cum Laude';
      case HonorsLevel.summaCumLaude:
        return 'Summa Cum Laude';
    }
  }
}

class GraduateSchoolReadiness {
  final bool isRelevant;
  final bool mastersProgramsReady;
  final bool phdProgramsReady;
  final bool professionalSchoolReady;
  final double? currentGPA;

  const GraduateSchoolReadiness({
    required this.isRelevant,
    required this.mastersProgramsReady,
    required this.phdProgramsReady,
    required this.professionalSchoolReady,
    this.currentGPA,
  });
}

class DeansListEligibility {
  final bool isEligible;
  final double threshold;
  final double gap;

  const DeansListEligibility({
    required this.isEligible,
    required this.threshold,
    required this.gap,
  });
}