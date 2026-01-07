import 'package:equatable/equatable.dart';

class Course extends Equatable {
  final String id;
  final String semesterId;
  final String courseCode;
  final String courseName;
  final int credits;
  final String? letterGrade;
  final double? gradePoint;
  final int attemptNumber;
  final CourseType courseType;

  const Course({
    required this.id,
    required this.semesterId,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    this.letterGrade,
    this.gradePoint,
    this.attemptNumber = 1,
    this.courseType = CourseType.major,
  });

  bool get isPassing => gradePoint != null && gradePoint! >= 2.0;
  bool get isGraded => gradePoint != null;
  double get qualityPoints => (gradePoint ?? 0.0) * credits;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      semesterId: json['semester_id'] as String,
      courseCode: json['course_code'] as String,
      courseName: json['course_name'] as String,
      credits: json['credits'] as int,
      letterGrade: json['letter_grade'] as String?,
      gradePoint: (json['grade_point'] as num?)?.toDouble(),
      attemptNumber: json['attempt_number'] as int? ?? 1,
      courseType: CourseType.values.firstWhere(
            (e) => e.toString() == 'CourseType.${json['course_type']}',
        orElse: () => CourseType.major,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semester_id': semesterId,
      'course_code': courseCode,
      'course_name': courseName,
      'credits': credits,
      'letter_grade': letterGrade,
      'grade_point': gradePoint,
      'attempt_number': attemptNumber,
      'course_type': courseType.name,
    };
  }

  Course copyWith({
    String? courseCode,
    String? courseName,
    int? credits,
    String? letterGrade,
    double? gradePoint,
    int? attemptNumber,
    CourseType? courseType,
  }) {
    return Course(
      id: id,
      semesterId: semesterId,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      credits: credits ?? this.credits,
      letterGrade: letterGrade ?? this.letterGrade,
      gradePoint: gradePoint ?? this.gradePoint,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      courseType: courseType ?? this.courseType,
    );
  }

  @override
  List<Object?> get props => [
    id,
    semesterId,
    courseCode,
    courseName,
    credits,
    letterGrade,
    gradePoint,
    attemptNumber,
    courseType,
  ];
}

enum CourseType {
  major,
  minor,
  elective,
  general,
}