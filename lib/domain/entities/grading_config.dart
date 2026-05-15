import 'dart:convert';

import 'package:equatable/equatable.dart';

/// User-defined grading configuration entity
///
/// WHY THIS IS A FIRST-CLASS ENTITY:
///
/// Grading systems vary significantly across:
/// - Countries (US 4.0, UK percentage, European ECTS)
/// - Institutions (some use 5.0 scale, weighted systems)
/// - Programs (honors vs. standard, graduate vs. undergraduate)
///
/// Hard-coding grade mappings makes the system:
/// - Unusable for non-US students
/// - Invalid for institutions with custom scales
/// - Impossible to adapt to policy changes
///
/// Making this configurable enables:
/// - International usage
/// - Institutional compliance
/// - Academic policy updates without code changes
/// - Multi-profile support (compare different grading systems)
///
/// BUSINESS RULE:
/// All GPA calculations MUST depend on GradingConfig, not constants.
/// This ensures system-wide consistency and allows safe recalculation
/// when grading policies change.
class GradingConfig extends Equatable {
  final String id;
  final String name; // e.g., "Standard US 4.0", "UK Percentage"
  final GradingSystemType systemType;
  final double maxGPA; // 4.0, 5.0, 100.0, etc.
  final double minGPA; // Usually 0.0
  final Map<String, double> gradeToPointMap; // Letter grade → GPA value
  final List<GPAClassification> classifications; // Dean's List, etc.
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastModified;

  const GradingConfig({
    required this.id,
    required this.name,
    required this.systemType,
    required this.maxGPA,
    this.minGPA = 0.0,
    required this.gradeToPointMap,
    required this.classifications,
    this.isDefault = false,
    required this.createdAt,
    this.lastModified,
  });

  /// Factory: Standard US 4.0 system
  factory GradingConfig.standardUS4Point0() {
    return GradingConfig(
      id: 'us_4_0_standard',
      name: 'US Standard 4.0 Scale',
      systemType: GradingSystemType.points4_0,
      maxGPA: 4.0,
      gradeToPointMap: const {
        'A+': 4.0,
        'A': 4.0,
        'A-': 3.7,
        'B+': 3.3,
        'B': 3.0,
        'B-': 2.7,
        'C+': 2.3,
        'C': 2.0,
        'C-': 1.7,
        'D+': 1.3,
        'D': 1.0,
        'D-': 0.7,
        'F': 0.0,
      },
      classifications: [
        GPAClassification(name: "Dean's List", minGPA: 3.5, color: 0xFF4CAF50),
        GPAClassification(
          name: 'Good Standing',
          minGPA: 3.0,
          color: 0xFF8BC34A,
        ),
        GPAClassification(name: 'Satisfactory', minGPA: 2.0, color: 0xFFFFC107),
        GPAClassification(name: 'Probation', minGPA: 1.0, color: 0xFFFF9800),
        GPAClassification(name: 'At Risk', minGPA: 0.0, color: 0xFFF44336),
      ],
      isDefault: true,
      createdAt: DateTime.now(),
    );
  }

  /// Factory: US 5.0 scale (some universities)
  factory GradingConfig.standardUS5Point0() {
    return GradingConfig(
      id: 'us_5_0_standard',
      name: 'US 5.0 Scale',
      systemType: GradingSystemType.points5_0,
      maxGPA: 5.0,
      gradeToPointMap: const {
        'A+': 5.0,
        'A': 5.0,
        'A-': 4.7,
        'B+': 4.3,
        'B': 4.0,
        'B-': 3.7,
        'C+': 3.3,
        'C': 3.0,
        'C-': 2.7,
        'D+': 2.3,
        'D': 2.0,
        'D-': 1.7,
        'F': 0.0,
      },
      classifications: [
        GPAClassification(
          name: 'Summa Cum Laude',
          minGPA: 4.7,
          color: 0xFF4CAF50,
        ),
        GPAClassification(
          name: 'Magna Cum Laude',
          minGPA: 4.3,
          color: 0xFF66BB6A,
        ),
        GPAClassification(name: 'Cum Laude', minGPA: 4.0, color: 0xFF8BC34A),
        GPAClassification(
          name: 'Good Standing',
          minGPA: 3.0,
          color: 0xFFFFC107,
        ),
        GPAClassification(name: 'At Risk', minGPA: 0.0, color: 0xFFF44336),
      ],
      isDefault: false,
      createdAt: DateTime.now(),
    );
  }

  /// Factory: UK Percentage System
  factory GradingConfig.ukPercentage() {
    return GradingConfig(
      id: 'uk_percentage',
      name: 'UK Percentage System',
      systemType: GradingSystemType.percentage,
      maxGPA: 100.0,
      gradeToPointMap: const {
        'First': 70.0,
        'Upper Second': 60.0,
        'Lower Second': 50.0,
        'Third': 40.0,
        'Fail': 0.0,
      },
      classifications: [
        GPAClassification(
          name: 'First Class Honours',
          minGPA: 70.0,
          color: 0xFF4CAF50,
        ),
        GPAClassification(
          name: 'Upper Second (2:1)',
          minGPA: 60.0,
          color: 0xFF8BC34A,
        ),
        GPAClassification(
          name: 'Lower Second (2:2)',
          minGPA: 50.0,
          color: 0xFFFFC107,
        ),
        GPAClassification(name: 'Third Class', minGPA: 40.0, color: 0xFFFF9800),
        GPAClassification(name: 'Fail', minGPA: 0.0, color: 0xFFF44336),
      ],
      isDefault: false,
      createdAt: DateTime.now(),
    );
  }

  /// Get classification for a given GPA
  GPAClassification getClassification(double gpa) {
    // Find the highest classification the GPA qualifies for
    GPAClassification? result;

    for (final classification in classifications) {
      if (gpa >= classification.minGPA) {
        if (result == null || classification.minGPA > result.minGPA) {
          result = classification;
        }
      }
    }

    return result ?? classifications.last;
  }

  /// Validate grade exists in system
  bool isValidGrade(String letterGrade) {
    return gradeToPointMap.containsKey(letterGrade);
  }

  /// Get grade point for letter grade
  double? getGradePoint(String letterGrade) {
    return gradeToPointMap[letterGrade];
  }

  /// Get all available letter grades
  List<String> get availableGrades => gradeToPointMap.keys.toList();

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'system_type': systemType.name,
      'max_gpa': maxGPA,
      'min_gpa': minGPA,
      'grade_to_point_map': gradeToPointMap,
      'classifications': classifications.map((c) => c.toJson()).toList(),
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory GradingConfig.fromJson(Map<String, dynamic> json) {
    final gradeMapRaw = json['grade_to_point_map'];
    final classificationsRaw = json['classifications'];
    final decodedGradeMap = gradeMapRaw is String
        ? jsonDecode(gradeMapRaw) as Map<String, dynamic>
        : gradeMapRaw as Map;
    final decodedClassifications = classificationsRaw is String
        ? jsonDecode(classificationsRaw) as List<dynamic>
        : classificationsRaw as List;
    final isDefaultRaw = json['is_default'];

    return GradingConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      systemType: GradingSystemType.values.firstWhere(
        (e) => e.name == json['system_type'],
      ),
      maxGPA: (json['max_gpa'] as num).toDouble(),
      minGPA: (json['min_gpa'] as num?)?.toDouble() ?? 0.0,
      gradeToPointMap: Map<String, double>.from(
        decodedGradeMap.map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      classifications: decodedClassifications
          .map((c) => GPAClassification.fromJson(c as Map<String, dynamic>))
          .toList(),
      isDefault: isDefaultRaw is bool
          ? isDefaultRaw
          : isDefaultRaw == 1 || isDefaultRaw == '1',
      createdAt: DateTime.parse(json['created_at'] as String),
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'] as String)
          : null,
    );
  }

  GradingConfig copyWith({
    String? name,
    GradingSystemType? systemType,
    double? maxGPA,
    double? minGPA,
    Map<String, double>? gradeToPointMap,
    List<GPAClassification>? classifications,
    bool? isDefault,
  }) {
    return GradingConfig(
      id: id,
      name: name ?? this.name,
      systemType: systemType ?? this.systemType,
      maxGPA: maxGPA ?? this.maxGPA,
      minGPA: minGPA ?? this.minGPA,
      gradeToPointMap: gradeToPointMap ?? this.gradeToPointMap,
      classifications: classifications ?? this.classifications,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      lastModified: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    systemType,
    maxGPA,
    minGPA,
    gradeToPointMap,
    classifications,
    isDefault,
    createdAt,
    lastModified,
  ];
}

/// Types of grading systems
enum GradingSystemType {
  points4_0, // US 4.0 scale
  points5_0, // US 5.0 scale
  percentage, // UK 0-100 percentage
  letterOnly, // Pure letter grades (no numeric)
  custom, // User-defined
}

/// GPA classification/standing definition
class GPAClassification extends Equatable {
  final String name; // e.g., "Dean's List"
  final double minGPA; // Minimum GPA to achieve this standing
  final int color; // Color code for UI display
  final String? description; // Optional explanation

  const GPAClassification({
    required this.name,
    required this.minGPA,
    required this.color,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'min_gpa': minGPA,
      'color': color,
      'description': description,
    };
  }

  factory GPAClassification.fromJson(Map<String, dynamic> json) {
    return GPAClassification(
      name: json['name'] as String,
      minGPA: (json['min_gpa'] as num).toDouble(),
      color: json['color'] as int,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props => [name, minGPA, color, description];
}
