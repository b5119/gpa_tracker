import 'package:equatable/equatable.dart';

/// A saved simulation state capturing hypothetical grades and computed GPA.
class SimulationSnapshot extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final double simulatedGpa;
  final Map<String, double> courseGradePoints; // courseId -> gradePoint
  final Map<String, double> courseCreditUnits; // courseId -> credits

  const SimulationSnapshot({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.simulatedGpa,
    required this.courseGradePoints,
    required this.courseCreditUnits,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    createdAt,
    simulatedGpa,
    courseGradePoints,
    courseCreditUnits,
  ];
}
