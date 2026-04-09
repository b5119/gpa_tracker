import 'package:equatable/equatable.dart';
import 'course.dart'; // CRITICAL: Import Course

class Semester extends Equatable {
  final String id;
  final String studentId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final SemesterStatus status;
  final List<Course> courses;

  const Semester({
    required this.id,
    required this.studentId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.courses = const [],
  });

  double? calculateGPA() {
    final gradedCourses = courses.where((c) => c.gradePoint != null).toList();

    if (gradedCourses.isEmpty) return null;

    double totalQualityPoints = 0.0;
    int totalCredits = 0;

    for (final course in gradedCourses) {
      totalQualityPoints += course.gradePoint! * course.credits;
      totalCredits += course.credits;
    }

    return totalCredits > 0 ? totalQualityPoints / totalCredits : null;
  }

  int get totalCredits => courses.fold(0, (sum, c) => sum + c.credits);

  int get earnedCredits =>
      courses.where((c) => c.isPassing).fold(0, (sum, c) => sum + c.credits);

  double get completionRate {
    final total = courses.length;
    if (total == 0) return 0.0;
    final completed = courses.where((c) => c.gradePoint != null).length;
    return completed / total;
  }

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as String,
      studentId: json['student_id'] as String, // Note: snake_case in DB
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: SemesterStatus.values.firstWhere(
        (e) => e.toString() == 'SemesterStatus.${json['status']}',
      ),
      courses:
          (json['courses'] as List<dynamic>?)
              ?.map((c) => Course.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId, // snake_case for DB
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status.name, // Use .name instead of .toString()
      'courses': courses.map((c) => c.toJson()).toList(),
    };
  }

  Semester copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    SemesterStatus? status,
    List<Course>? courses,
  }) {
    return Semester(
      id: id,
      studentId: studentId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      courses: courses ?? this.courses,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    name,
    startDate,
    endDate,
    status,
    courses,
  ];
}

enum SemesterStatus { upcoming, inProgress, completed }
