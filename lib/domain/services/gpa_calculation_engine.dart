// =============================================================================
// GPA CALCULATION ENGINE - DOMAIN SERVICE
// =============================================================================
// This service contains pure business logic for GPA calculations.
// It handles credit-weighted GPA, retake policies, and normalization across
// different grading scales (4.0, 5.0, etc.).
//
// WHY THIS EXISTS:
// GPA calculation is complex domain logic that must be:
// 1. Consistent across the application
// 2. Testable in isolation
// 3. Reusable for different scenarios (semester, cumulative, projected)
// 4. Configurable for different institutional policies

import 'dart:math' as math;

/// Core GPA calculation service following domain-driven design principles.
///
/// This service is stateless and pure - all calculations are deterministic
/// based on input data. This makes it highly testable and thread-safe.
class GPACalculationEngine {
  /// Grade point mapping for standard letter grades on 4.0 scale
  static const Map<String, double> standardGradePoints4_0 = {
    'A+': 4.0, 'A': 4.0, 'A-': 3.7,
    'B+': 3.3, 'B': 3.0, 'B-': 2.7,
    'C+': 2.3, 'C': 2.0, 'C-': 1.7,
    'D+': 1.3, 'D': 1.0, 'D-': 0.7,
    'F': 0.0,
  };

  /// Grade point mapping for 5.0 scale (some institutions)
  static const Map<String, double> standardGradePoints5_0 = {
    'A+': 5.0, 'A': 5.0, 'A-': 4.7,
    'B+': 4.3, 'B': 4.0, 'B-': 3.7,
    'C+': 3.3, 'C': 3.0, 'C-': 2.7,
    'D+': 2.3, 'D': 2.0, 'D-': 1.7,
    'F': 0.0,
  };

  final Map<String, double> _gradePointMap;
  final double _gpaScale;

  /// Creates a GPA calculation engine with specified grading scale.
  ///
  /// [gpaScale] - Maximum GPA value (typically 4.0 or 5.0)
  /// [customGradePoints] - Custom grade mapping (optional)
  GPACalculationEngine({
    double gpaScale = 4.0,
    Map<String, double>? customGradePoints,
  })  : _gpaScale = gpaScale,
        _gradePointMap = customGradePoints ??
            (gpaScale == 5.0
                ? standardGradePoints5_0
                : standardGradePoints4_0);

  // ===========================================================================
  // CORE GPA CALCULATION METHODS
  // ===========================================================================

  /// Calculates credit-weighted GPA for a list of courses.
  ///
  /// Formula: Σ(grade_point × credits) / Σ(credits)
  ///
  /// MATHEMATICAL JUSTIFICATION:
  /// Credit weighting ensures courses with more academic weight contribute
  /// proportionally more to GPA. A 4-credit A should impact GPA more than
  /// a 1-credit A. This is the industry-standard calculation method used
  /// by virtually all accredited institutions.
  ///
  /// EDGE CASES HANDLED:
  /// - Empty course list → returns null
  /// - Zero total credits → returns null
  /// - Courses without grades → excluded from calculation
  /// - Negative credits → throws ArgumentError
  ///
  /// Returns: Calculated GPA or null if insufficient data
  double? calculateWeightedGPA(List<CourseGrade> courses) {
    if (courses.isEmpty) return null;

    // Filter to only graded courses
    final gradedCourses = courses.where((c) => c.gradePoint != null).toList();
    if (gradedCourses.isEmpty) return null;

    double totalQualityPoints = 0.0;
    int totalCredits = 0;

    for (final course in gradedCourses) {
      if (course.credits < 0) {
        throw ArgumentError('Course credits cannot be negative: ${course.credits}');
      }

      totalQualityPoints += course.gradePoint! * course.credits;
      totalCredits += course.credits;
    }

    if (totalCredits == 0) return null;

    final gpa = totalQualityPoints / totalCredits;

    // Clamp to scale (shouldn't exceed max, but handle floating point errors)
    return math.min(gpa, _gpaScale);
  }

  /// Calculates cumulative GPA across multiple semesters with retake policy.
  ///
  /// WHY RETAKE POLICIES MATTER:
  /// Students often retake courses to improve grades. Different institutions
  /// handle this differently:
  /// - REPLACE: Only most recent attempt counts (most lenient)
  /// - AVERAGE: All attempts averaged (middle ground)
  /// - BEST: Highest grade counts (rarely used, very lenient)
  ///
  /// The policy choice significantly impacts calculated GPA and must be
  /// configurable per institution.
  ///
  /// [semesterCourses] - Map of semester ID to course list
  /// [retakePolicy] - How to handle repeated courses
  /// Returns: Cumulative GPA result with metadata
  CumulativeGPAResult calculateCumulativeGPA(
      Map<String, List<CourseGrade>> semesterCourses,
      RetakePolicy retakePolicy,
      ) {
    // Flatten all courses across semesters
    final allCourses = semesterCourses.values.expand((c) => c).toList();

    // Group courses by course code to identify retakes
    final courseGroups = <String, List<CourseGrade>>{};
    for (final course in allCourses) {
      courseGroups.putIfAbsent(course.courseCode, () => []).add(course);
    }

    // Apply retake policy to get final grade for each course
    final finalCourses = <CourseGrade>[];
    for (final entry in courseGroups.entries) {
      final attempts = entry.value;
      final finalCourse = _applyRetakePolicy(attempts, retakePolicy);
      if (finalCourse != null) {
        finalCourses.add(finalCourse);
      }
    }

    // Calculate GPA from final courses
    final gpa = calculateWeightedGPA(finalCourses);

    final totalCreditsAttempted = finalCourses.fold<int>(
      0,
          (sum, c) => sum + c.credits,
    );

    final totalCreditsEarned = finalCourses
        .where((c) => c.gradePoint != null && c.gradePoint! >= 2.0)
        .fold<int>(0, (sum, c) => sum + c.credits);

    final totalQualityPoints = finalCourses
        .where((c) => c.gradePoint != null)
        .fold<double>(0, (sum, c) => sum + (c.gradePoint! * c.credits));

    return CumulativeGPAResult(
      gpa: gpa ?? 0.0,
      totalCreditsAttempted: totalCreditsAttempted,
      totalCreditsEarned: totalCreditsEarned,
      totalQualityPoints: totalQualityPoints,
      coursesIncluded: finalCourses.length,
      retakesProcessed: courseGroups.values.where((v) => v.length > 1).length,
    );
  }

  /// Applies retake policy to determine final grade from multiple attempts.
  ///
  /// Returns the course that should count toward GPA calculation.
  CourseGrade? _applyRetakePolicy(
      List<CourseGrade> attempts,
      RetakePolicy policy,
      ) {
    if (attempts.isEmpty) return null;
    if (attempts.length == 1) return attempts.first;

    // Filter to only graded attempts
    final gradedAttempts = attempts.where((a) => a.gradePoint != null).toList();
    if (gradedAttempts.isEmpty) return attempts.last; // Return most recent even if ungraded

    switch (policy) {
      case RetakePolicy.replace:
      // Return most recent graded attempt
        return gradedAttempts.last;

      case RetakePolicy.average:
      // Create synthetic course with averaged grade
        final avgGrade = gradedAttempts
            .map((a) => a.gradePoint!)
            .reduce((a, b) => a + b) / gradedAttempts.length;

        return CourseGrade(
          courseCode: gradedAttempts.first.courseCode,
          courseName: gradedAttempts.first.courseName,
          credits: gradedAttempts.first.credits,
          gradePoint: avgGrade,
          letterGrade: _gradePointToLetter(avgGrade),
        );

      case RetakePolicy.best:
      // Return attempt with highest grade
        return gradedAttempts.reduce(
              (best, current) =>
          current.gradePoint! > best.gradePoint! ? current : best,
        );
    }
  }

  /// Converts grade point to letter grade (approximate, for display)
  String _gradePointToLetter(double gradePoint) {
    for (final entry in _gradePointMap.entries) {
      if ((gradePoint - entry.value).abs() < 0.05) {
        return entry.key;
      }
    }
    return 'N/A';
  }

  // ===========================================================================
  // REVERSE GPA CALCULATION (FOR GOAL SETTING)
  // ===========================================================================

  /// Calculates required GPA in remaining credits to achieve target cumulative GPA.
  ///
  /// MATHEMATICAL DERIVATION:
  /// Target GPA = (Current Quality Points + Required Quality Points) /
  ///              (Current Credits + Remaining Credits)
  ///
  /// Solving for Required GPA:
  /// Required GPA = (Target GPA × Total Credits - Current Quality Points) /
  ///                Remaining Credits
  ///
  /// WHY THIS IS USEFUL:
  /// Students need to know "What GPA do I need to earn in my remaining courses
  /// to graduate with a 3.5?" This calculation provides that answer and is
  /// critical for academic planning and goal-setting.
  ///
  /// Returns null if target is mathematically impossible.
  RequiredGPAResult? calculateRequiredGPA({
    required double currentCumulativeGPA,
    required int currentTotalCredits,
    required int remainingCredits,
    required double targetGPA,
  }) {
    if (remainingCredits <= 0) {
      return RequiredGPAResult(
        requiredGPA: 0.0,
        isAchievable: false,
        reason: 'No remaining credits to improve GPA',
      );
    }

    if (targetGPA > _gpaScale) {
      return RequiredGPAResult(
        requiredGPA: 0.0,
        isAchievable: false,
        reason: 'Target GPA exceeds maximum scale of $_gpaScale',
      );
    }

    // Calculate current quality points
    final currentQualityPoints = currentCumulativeGPA * currentTotalCredits;

    // Calculate total credits after completion
    final totalFutureCredits = currentTotalCredits + remainingCredits;

    // Calculate required quality points to achieve target
    final targetQualityPoints = targetGPA * totalFutureCredits;

    // Calculate required quality points from remaining credits
    final requiredQualityPoints = targetQualityPoints - currentQualityPoints;

    // Calculate required GPA for remaining credits
    final requiredGPA = requiredQualityPoints / remainingCredits;

    // Check if achievable (can't exceed max GPA scale)
    final isAchievable = requiredGPA <= _gpaScale && requiredGPA >= 0;

    String reason = '';
    if (!isAchievable) {
      if (requiredGPA > _gpaScale) {
        reason = 'Would require GPA of ${requiredGPA.toStringAsFixed(2)}, '
            'which exceeds maximum of $_gpaScale';
      } else if (requiredGPA < 0) {
        reason = 'Current GPA already exceeds target';
      }
    }

    return RequiredGPAResult(
      requiredGPA: math.max(0, math.min(requiredGPA, _gpaScale)),
      isAchievable: isAchievable,
      reason: reason,
      remainingCredits: remainingCredits,
      currentGPA: currentCumulativeGPA,
      targetGPA: targetGPA,
    );
  }

  // ===========================================================================
  // WHAT-IF SIMULATION
  // ===========================================================================

  /// Simulates GPA impact of hypothetical course grades.
  ///
  /// WHY THIS EXISTS:
  /// Students need to understand "If I get an A in Physics and a B in Calculus,
  /// what will my GPA be?" This simulation enables informed decision-making
  /// about course selection, workload management, and academic strategy.
  ///
  /// [currentGPA] - Starting cumulative GPA
  /// [currentCredits] - Current total credits
  /// [hypotheticalCourses] - Courses with projected grades
  /// Returns: Projected new GPA and analysis
  WhatIfResult simulateGPAImpact({
    required double currentGPA,
    required int currentCredits,
    required List<CourseGrade> hypotheticalCourses,
  }) {
    final currentQualityPoints = currentGPA * currentCredits;

    double hypotheticalQualityPoints = 0.0;
    int hypotheticalCredits = 0;

    for (final course in hypotheticalCourses) {
      if (course.gradePoint != null) {
        hypotheticalQualityPoints += course.gradePoint! * course.credits;
        hypotheticalCredits += course.credits;
      }
    }

    final totalQualityPoints = currentQualityPoints + hypotheticalQualityPoints;
    final totalCredits = currentCredits + hypotheticalCredits;

    final newGPA = totalCredits > 0 ? totalQualityPoints / totalCredits : currentGPA;
    final gpaChange = newGPA - currentGPA;

    return WhatIfResult(
      originalGPA: currentGPA,
      projectedGPA: newGPA,
      gpaChange: gpaChange,
      hypotheticalCourses: hypotheticalCourses.length,
      hypotheticalCredits: hypotheticalCredits,
      impact: _categorizeImpact(gpaChange),
    );
  }

  GPAImpact _categorizeImpact(double change) {
    if (change.abs() < 0.05) return GPAImpact.negligible;
    if (change > 0.2) return GPAImpact.majorIncrease;
    if (change > 0.05) return GPAImpact.moderateIncrease;
    if (change < -0.2) return GPAImpact.majorDecrease;
    return GPAImpact.moderateDecrease;
  }

  // ===========================================================================
  // GRADE CONVERSION UTILITIES
  // ===========================================================================

  /// Converts letter grade to grade point using configured scale.
  double? letterToGradePoint(String letterGrade) {
    return _gradePointMap[letterGrade.toUpperCase()];
  }

  /// Normalizes GPA from one scale to another.
  /// Example: Convert 4.5 on 5.0 scale to equivalent on 4.0 scale
  double normalizeGPA(double gpa, double fromScale, double toScale) {
    if (fromScale == toScale) return gpa;
    return (gpa / fromScale) * toScale;
  }
}

// =============================================================================
// SUPPORTING DATA CLASSES
// =============================================================================

/// Simplified course representation for calculations.
class CourseGrade {
  final String courseCode;
  final String courseName;
  final int credits;
  final double? gradePoint;
  final String? letterGrade;

  const CourseGrade({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    this.gradePoint,
    this.letterGrade,
  });
}

/// Result of cumulative GPA calculation.
class CumulativeGPAResult {
  final double gpa;
  final int totalCreditsAttempted;
  final int totalCreditsEarned;
  final double totalQualityPoints;
  final int coursesIncluded;
  final int retakesProcessed;

  const CumulativeGPAResult({
    required this.gpa,
    required this.totalCreditsAttempted,
    required this.totalCreditsEarned,
    required this.totalQualityPoints,
    required this.coursesIncluded,
    required this.retakesProcessed,
  });

  /// GPA rounded to 2 decimal places (standard display)
  double get displayGPA => double.parse(gpa.toStringAsFixed(2));

  /// Percentage of attempted credits that were earned
  double get completionRate =>
      totalCreditsAttempted > 0
          ? totalCreditsEarned / totalCreditsAttempted
          : 0.0;
}

/// Result of required GPA calculation.
class RequiredGPAResult {
  final double requiredGPA;
  final bool isAchievable;
  final String reason;
  final int? remainingCredits;
  final double? currentGPA;
  final double? targetGPA;

  const RequiredGPAResult({
    required this.requiredGPA,
    required this.isAchievable,
    required this.reason,
    this.remainingCredits,
    this.currentGPA,
    this.targetGPA,
  });

  /// User-friendly display of required GPA
  String get displayRequiredGPA => requiredGPA.toStringAsFixed(2);

  /// Difficulty assessment
  String get difficultyLevel {
    if (!isAchievable) return 'Impossible';
    if (requiredGPA >= 3.8) return 'Extremely Difficult';
    if (requiredGPA >= 3.5) return 'Very Difficult';
    if (requiredGPA >= 3.0) return 'Challenging';
    if (requiredGPA >= 2.5) return 'Moderate';
    return 'Achievable';
  }
}

/// Result of what-if simulation.
class WhatIfResult {
  final double originalGPA;
  final double projectedGPA;
  final double gpaChange;
  final int hypotheticalCourses;
  final int hypotheticalCredits;
  final GPAImpact impact;

  const WhatIfResult({
    required this.originalGPA,
    required this.projectedGPA,
    required this.gpaChange,
    required this.hypotheticalCourses,
    required this.hypotheticalCredits,
    required this.impact,
  });

  /// Display-friendly GPA change with sign
  String get displayChange {
    final sign = gpaChange >= 0 ? '+' : '';
    return '$sign${gpaChange.toStringAsFixed(2)}';
  }
}

enum GPAImpact {
  majorIncrease,
  moderateIncrease,
  negligible,
  moderateDecrease,
  majorDecrease,
}

enum RetakePolicy {
  replace,
  average,
  best,
}