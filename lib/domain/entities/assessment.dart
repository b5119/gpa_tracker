import 'package:equatable/equatable.dart';

/// Assessment entity representing a graded item within a course.
class Assessment extends Equatable {
  final String id;
  final String courseId;
  final String name;
  final AssessmentType type;

  /// Weight as a percentage (0-100). Course weights should sum to 100.
  final double weightPercent;
  final double totalPoints;
  final double? pointsEarned;
  final DateTime? dueDate;
  final DateTime? submittedDate;
  final bool isDropped;

  const Assessment({
    required this.id,
    required this.courseId,
    required this.name,
    required this.type,
    required this.weightPercent,
    required this.totalPoints,
    this.pointsEarned,
    this.dueDate,
    this.submittedDate,
    this.isDropped = false,
  });

  double? get percentScore {
    if (pointsEarned == null || totalPoints == 0) return null;
    return (pointsEarned! / totalPoints) * 100;
  }

  Assessment copyWith({
    String? id,
    String? courseId,
    String? name,
    AssessmentType? type,
    double? weightPercent,
    double? totalPoints,
    double? pointsEarned,
    DateTime? dueDate,
    DateTime? submittedDate,
    bool? isDropped,
  }) {
    return Assessment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      type: type ?? this.type,
      weightPercent: weightPercent ?? this.weightPercent,
      totalPoints: totalPoints ?? this.totalPoints,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      dueDate: dueDate ?? this.dueDate,
      submittedDate: submittedDate ?? this.submittedDate,
      isDropped: isDropped ?? this.isDropped,
    );
  }

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      name: json['name'] as String,
      type: AssessmentType.values.firstWhere(
        (t) => t.name == (json['type'] as String),
        orElse: () => AssessmentType.assignment,
      ),
      weightPercent:
          (json['weight_percent'] as num?)?.toDouble() ??
          (json['weight'] as num?)?.toDouble() ??
          0,
      totalPoints: (json['total_points'] as num).toDouble(),
      pointsEarned:
          (json['points_earned'] as num?)?.toDouble() ??
          (json['earned_points'] as num?)?.toDouble(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      submittedDate: json['submitted_date'] != null
          ? DateTime.parse(json['submitted_date'] as String)
          : null,
      isDropped: (json['is_dropped'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'type': type.name,
      'weight_percent': weightPercent,
      'total_points': totalPoints,
      'points_earned': pointsEarned,
      'due_date': dueDate?.toIso8601String(),
      'submitted_date': submittedDate?.toIso8601String(),
      'is_dropped': isDropped ? 1 : 0,
    };
  }

  @override
  List<Object?> get props => [
    id,
    courseId,
    name,
    type,
    weightPercent,
    totalPoints,
    pointsEarned,
    dueDate,
    submittedDate,
    isDropped,
  ];
}

enum AssessmentType { assignment, quiz, midterm, finalExam, project }
