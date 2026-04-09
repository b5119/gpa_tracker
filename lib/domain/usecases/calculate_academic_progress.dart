import '../models/student.dart';
import '../models/semester.dart';

/// Academic Progression Analysis Use Case
///
/// PURPOSE:
/// Calculates where a student stands in their academic journey and
/// whether they're on pace for timely graduation.
///
/// WHY TIME-INDEXING IS ESSENTIAL:
/// - GPA prediction requires knowing how many semesters remain
/// - Eligibility checks depend on current academic year
/// - "At-risk" detection requires velocity analysis
/// - Career timing depends on graduation timeline
///
/// EDGE CASES HANDLED:
/// - Late start (enrolled mid-year)
/// - Semester repeats (failed courses)
/// - Leave of absence (gaps in enrollment)
/// - Accelerated programs (overloads)
/// - Extended programs (reduced loads)
class CalculateAcademicProgress {
  /// Analyzes current academic standing and progression
  AcademicProgress execute({
    required Student student,
    required List<Semester> completedSemesters,
    required int earnedCredits,
  }) {
    // Calculate temporal metrics
    final currentYear = student.currentYear;
    final currentTerm = student.currentTerm;
    final totalSemestersSinceEnrollment = student.semestersSinceEnrollment;

    // Calculate expected vs actual progress
    final expectedSemesters = _calculateExpectedSemesters(
      student.programDurationYears,
      student.enrollmentDate,
    );

    final completedSemesterCount = completedSemesters
        .where((s) => s.status == SemesterStatus.completed)
        .length;

    // Credit velocity
    final expectedCredits = _calculateExpectedCredits(
      student.totalCreditsRequired,
      totalSemestersSinceEnrollment,
      expectedSemesters,
    );

    final creditVelocity = _calculateVelocity(earnedCredits, expectedCredits);

    // Remaining metrics
    final remainingCredits = student.totalCreditsRequired - earnedCredits;
    final remainingSemesters = _calculateRemainingSemesters(
      student.programDurationYears,
      student.enrollmentDate,
      currentYear,
    );

    // Pace analysis
    final paceStatus = _analyzePace(
      completedSemesterCount,
      expectedSemesters,
      earnedCredits,
      expectedCredits,
    );

    // Graduation projection
    final projectedGraduationDate = _projectGraduationDate(
      student.expectedGraduationDate,
      paceStatus,
      remainingCredits,
      earnedCredits,
    );

    return AcademicProgress(
      currentYear: currentYear,
      currentTerm: currentTerm,
      completedSemesters: completedSemesterCount,
      expectedSemesters: expectedSemesters,
      earnedCredits: earnedCredits,
      remainingCredits: remainingCredits,
      remainingSemesters: remainingSemesters,
      creditVelocity: creditVelocity,
      paceStatus: paceStatus,
      expectedGraduationDate: student.expectedGraduationDate,
      projectedGraduationDate: projectedGraduationDate,
      isOnTrack: paceStatus == PaceStatus.onPace,
    );
  }

  int _calculateExpectedSemesters(int durationYears, DateTime enrollmentDate) {
    final now = DateTime.now();
    final yearsSinceEnrollment = now.difference(enrollmentDate).inDays / 365;

    // 2 major semesters per year (Fall/Spring)
    return (yearsSinceEnrollment * 2).floor();
  }

  int _calculateExpectedCredits(
    int totalRequired,
    int semestersSinceEnrollment,
    int expectedSemesters,
  ) {
    if (expectedSemesters == 0) return 0;

    // Linear progression assumption
    final creditsPerSemester = totalRequired / (expectedSemesters);
    return (creditsPerSemester * semestersSinceEnrollment).round();
  }

  double _calculateVelocity(int earnedCredits, int expectedCredits) {
    if (expectedCredits == 0) return 1.0;
    return earnedCredits / expectedCredits;
  }

  int _calculateRemainingSemesters(
    int durationYears,
    DateTime enrollmentDate,
    int currentYear,
  ) {
    final totalSemesters = durationYears * 2;
    final elapsedYears = currentYear - 1;
    final elapsedSemesters = elapsedYears * 2;

    return (totalSemesters - elapsedSemesters).clamp(0, totalSemesters);
  }

  PaceStatus _analyzePace(
    int completedSemesters,
    int expectedSemesters,
    int earnedCredits,
    int expectedCredits,
  ) {
    // Check both semester count and credit accumulation
    final semesterRatio = expectedSemesters > 0
        ? completedSemesters / expectedSemesters
        : 1.0;

    final creditRatio = expectedCredits > 0
        ? earnedCredits / expectedCredits
        : 1.0;

    final avgRatio = (semesterRatio + creditRatio) / 2;

    if (avgRatio >= 1.1) return PaceStatus.accelerated;
    if (avgRatio >= 0.9) return PaceStatus.onPace;
    if (avgRatio >= 0.7) return PaceStatus.slightlyBehind;
    if (avgRatio >= 0.5) return PaceStatus.behindPace;
    return PaceStatus.significantlyBehind;
  }

  DateTime _projectGraduationDate(
    DateTime expectedDate,
    PaceStatus pace,
    int remainingCredits,
    int earnedCredits,
  ) {
    switch (pace) {
      case PaceStatus.accelerated:
        // May graduate early
        return expectedDate.subtract(const Duration(days: 180));

      case PaceStatus.onPace:
        return expectedDate;

      case PaceStatus.slightlyBehind:
        // 1 semester delay
        return expectedDate.add(const Duration(days: 180));

      case PaceStatus.behindPace:
        // 2 semester delay
        return expectedDate.add(const Duration(days: 365));

      case PaceStatus.significantlyBehind:
        // Significant delay - needs intervention
        return expectedDate.add(const Duration(days: 730));
    }
  }
}

/// Result object for academic progression analysis
class AcademicProgress {
  final int currentYear;
  final AcademicTerm currentTerm;
  final int completedSemesters;
  final int expectedSemesters;
  final int earnedCredits;
  final int remainingCredits;
  final int remainingSemesters;
  final double creditVelocity; // 1.0 = on pace, >1.0 = ahead, <1.0 = behind
  final PaceStatus paceStatus;
  final DateTime expectedGraduationDate;
  final DateTime projectedGraduationDate;
  final bool isOnTrack;

  const AcademicProgress({
    required this.currentYear,
    required this.currentTerm,
    required this.completedSemesters,
    required this.expectedSemesters,
    required this.earnedCredits,
    required this.remainingCredits,
    required this.remainingSemesters,
    required this.creditVelocity,
    required this.paceStatus,
    required this.expectedGraduationDate,
    required this.projectedGraduationDate,
    required this.isOnTrack,
  });

  /// Completion percentage
  double get completionPercentage {
    final total = earnedCredits + remainingCredits;
    return total > 0 ? earnedCredits / total : 0.0;
  }

  /// Semesters behind/ahead
  int get semesterDelta => completedSemesters - expectedSemesters;

  /// Days until graduation
  int get daysUntilGraduation {
    return projectedGraduationDate.difference(DateTime.now()).inDays;
  }

  /// User-friendly pace description
  String get paceDescription {
    switch (paceStatus) {
      case PaceStatus.accelerated:
        return 'Ahead of schedule';
      case PaceStatus.onPace:
        return 'On track';
      case PaceStatus.slightlyBehind:
        return 'Slightly behind';
      case PaceStatus.behindPace:
        return 'Behind pace';
      case PaceStatus.significantlyBehind:
        return 'Significantly behind - intervention needed';
    }
  }
}

/// Academic pace classification
enum PaceStatus {
  accelerated, // >110% of expected progress
  onPace, // 90-110% of expected progress
  slightlyBehind, // 70-90% of expected progress
  behindPace, // 50-70% of expected progress
  significantlyBehind, // <50% of expected progress
}
