// =============================================================================
// GPA PROJECTION MODEL
// =============================================================================
/// Represents a predicted future GPA scenario.
///
/// This value object encapsulates the results of predictive modeling,
/// including best/worst case scenarios and confidence metrics.
class GPAProjection extends Equatable {
  final String studentId;
  final DateTime projectedDate; // When this GPA is expected to be achieved
  final double predictedGPA; // Most likely GPA outcome
  final double bestCaseGPA; // Optimistic scenario
  final double worstCaseGPA; // Pessimistic scenario
  final double confidenceScore; // 0.0 to 1.0 (1.0 = highly confident)
  final int remainingCredits; // Credits left to complete
  final String methodology; // "linear_regression", "monte_carlo", etc.
  final Map<String, dynamic> metadata; // Additional context

  const GPAProjection({
    required this.studentId,
    required this.projectedDate,
    required this.predictedGPA,
    required this.bestCaseGPA,
    required this.worstCaseGPA,
    required this.confidenceScore,
    required this.remainingCredits,
    required this.methodology,
    this.metadata = const {},
  });

  /// Range of possible outcomes (best - worst)
  double get projectionRange => bestCaseGPA - worstCaseGPA;

  /// Whether this projection is reliable enough to act on
  bool get isReliable => confidenceScore >= 0.6 && projectionRange <= 0.5;

  factory GPAProjection.fromJson(Map<String, dynamic> json) {
    return GPAProjection(
      studentId: json['studentId'] as String,
      projectedDate: DateTime.parse(json['projectedDate'] as String),
      predictedGPA: (json['predictedGPA'] as num).toDouble(),
      bestCaseGPA: (json['bestCaseGPA'] as num).toDouble(),
      worstCaseGPA: (json['worstCaseGPA'] as num).toDouble(),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      remainingCredits: json['remainingCredits'] as int,
      methodology: json['methodology'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'projectedDate': projectedDate.toIso8601String(),
      'predictedGPA': predictedGPA,
      'bestCaseGPA': bestCaseGPA,
      'worstCaseGPA': worstCaseGPA,
      'confidenceScore': confidenceScore,
      'remainingCredits': remainingCredits,
      'methodology': methodology,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    studentId,
    projectedDate,
    predictedGPA,
    bestCaseGPA,
    worstCaseGPA,
    confidenceScore,
    remainingCredits,
    methodology,
    metadata,
  ];
}