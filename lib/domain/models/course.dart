// =============================================================================
// COURSE MODEL
// =============================================================================
/// Represents an individual course within a semester.
///
/// Courses are the atomic unit of academic work. Each course has credits,
/// a grade, and metadata. Multiple attempts of the same course are tracked
/// via the attemptNumber field.
class Course extends Equatable {
  final String id;
  final String semesterId; // Foreign key to Semester
  final String courseCode; // e.g., "CS101"
  final String courseName; // e.g., "Introduction to Programming"
  final int credits; // Credit hours (typically 1-4)
  final String? letterGrade; // "A", "B+", "C", etc. (null if in progress)
  final double? gradePoint; // Numeric grade on GPA scale (null if in progress)
  final int attemptNumber; // 1 for first attempt, 2 for retake, etc.
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

  /// Whether this course was passed (typically >= 2.0 on 4.0 scale)
  bool get isPassing => gradePoint != null && gradePoint! >= 2.0;

  /// Whether this course has been graded
  bool get isGraded => gradePoint != null;

  /// Quality points earned (grade × credits)
  double get qualityPoints => (gradePoint ?? 0.0) * credits;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      semesterId: json['semesterId'] as String,
      courseCode: json['courseCode'] as String,
      courseName: json['courseName'] as String,
      credits: json['credits'] as int,
      letterGrade: json['letterGrade'] as String?,
      gradePoint: (json['gradePoint'] as num?)?.toDouble(),
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      courseType: CourseType.values.firstWhere(
            (e) => e.toString() == json['courseType'],
        orElse: () => CourseType.major,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semesterId': semesterId,
      'courseCode': courseCode,
      'courseName': courseName,
      'credits': credits,
      'letterGrade': letterGrade,
      'gradePoint': gradePoint,
      'attemptNumber': attemptNumber,
      'courseType': courseType.toString(),
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
  major, // Core major requirement
  minor, // Minor requirement
  elective, // Free elective
  general, // General education
}