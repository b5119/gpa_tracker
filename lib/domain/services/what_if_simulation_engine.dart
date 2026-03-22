import '../entities/simulation_snapshot.dart';
import '../models/course.dart';
import '../models/semester.dart';

class WhatIfSimulationEngine {
  /// Clone current semesters (shallow copy of course list) to start a simulation.
  List<Semester> cloneSemesters(List<Semester> semesters) {
    return semesters
        .map((s) => s.copyWith(courses: List<Course>.from(s.courses)))
        .toList();
  }

  /// Calculate simulated GPA using hypothetical course grade points.
  /// simulatedGPA = Σ(gradePoint * credits) / Σ(credits)
  double? calculateSimulatedGpa(
    Map<String, double> courseGradePoints,
    Map<String, double> courseCredits,
  ) {
    double totalQuality = 0;
    double totalCredits = 0;

    courseGradePoints.forEach((courseId, gpa) {
      final credits = courseCredits[courseId] ?? 0;
      totalQuality += gpa * credits;
      totalCredits += credits;
    });

    if (totalCredits == 0) return null;
    return totalQuality / totalCredits;
  }

  SimulationSnapshot snapshot({
    required String id,
    required String name,
    required Map<String, double> courseGradePoints,
    required Map<String, double> courseCreditUnits,
  }) {
    final gpa =
        calculateSimulatedGpa(courseGradePoints, courseCreditUnits) ?? 0.0;
    return SimulationSnapshot(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      simulatedGpa: gpa,
      courseGradePoints: Map.unmodifiable(courseGradePoints),
      courseCreditUnits: Map.unmodifiable(courseCreditUnits),
    );
  }
}
