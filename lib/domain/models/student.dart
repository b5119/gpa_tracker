import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final String id;
  final String name;
  final String email;
  final String program;
  final double gpaScale;
  final DateTime enrollmentDate;
  final int totalCreditsRequired;
  final RetakePolicy retakePolicy;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.program,
    this.gpaScale = 4.0,
    required this.enrollmentDate,
    required this.totalCreditsRequired,
    this.retakePolicy = RetakePolicy.replace,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      program: json['program'] as String,
      gpaScale: (json['gpa_scale'] as num).toDouble(),
      enrollmentDate: DateTime.parse(json['enrollment_date'] as String),
      totalCreditsRequired: json['total_credits_required'] as int,
      retakePolicy: RetakePolicy.values.firstWhere(
            (e) => e.toString() == 'RetakePolicy.${json['retake_policy']}',
        orElse: () => RetakePolicy.replace,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'program': program,
      'gpa_scale': gpaScale,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'total_credits_required': totalCreditsRequired,
      'retake_policy': retakePolicy.name,
    };
  }

  Student copyWith({
    String? name,
    String? email,
    String? program,
    double? gpaScale,
    DateTime? enrollmentDate,
    int? totalCreditsRequired,
    RetakePolicy? retakePolicy,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      program: program ?? this.program,
      gpaScale: gpaScale ?? this.gpaScale,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      totalCreditsRequired: totalCreditsRequired ?? this.totalCreditsRequired,
      retakePolicy: retakePolicy ?? this.retakePolicy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    program,
    gpaScale,
    enrollmentDate,
    totalCreditsRequired,
    retakePolicy,
  ];
}

enum RetakePolicy {
  replace,
  average,
  best,
}