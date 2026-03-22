import 'package:equatable/equatable.dart';

/// Historical course performance used for grade prediction.
class PastCoursePerformance extends Equatable {
  final String courseCode;
  final double gradePoint; // GPA points earned (e.g., 3.3)
  final int credits;
  final int difficulty; // user-rated 1-5
  final DateTime completedAt;

  const PastCoursePerformance({
    required this.courseCode,
    required this.gradePoint,
    required this.credits,
    required this.difficulty,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [
    courseCode,
    gradePoint,
    credits,
    difficulty,
    completedAt,
  ];
}
