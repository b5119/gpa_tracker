// =============================================================================
// CAREER SECTOR MODEL
// =============================================================================
/// Represents an employment sector with GPA requirements.
///
/// Different industries have different GPA expectations. This model captures
/// minimum viable GPAs and competitive thresholds for various career paths.
class CareerSector extends Equatable {
  final String id;
  final String name; // e.g., "Investment Banking"
  final String category; // e.g., "Finance"
  final double minimumGPA; // Absolute minimum to be considered
  final double competitiveGPA; // GPA needed to be competitive
  final double targetGPA; // Ideal GPA for top opportunities
  final String description;
  final List<String> typicalRoles; // Common job titles in this sector
  final String region; // "US", "EU", "Global", etc.

  const CareerSector({
    required this.id,
    required this.name,
    required this.category,
    required this.minimumGPA,
    required this.competitiveGPA,
    required this.targetGPA,
    required this.description,
    required this.typicalRoles,
    this.region = 'Global',
  });

  /// Calculates fitness score (0.0 to 1.0) for a given GPA
  ///
  /// Returns:
  /// - 0.0 if below minimum
  /// - 0.0-0.5 between minimum and competitive
  /// - 0.5-1.0 between competitive and target
  /// - 1.0 if at or above target
  double calculateFitScore(double currentGPA) {
    if (currentGPA < minimumGPA) return 0.0;
    if (currentGPA >= targetGPA) return 1.0;

    if (currentGPA < competitiveGPA) {
      // Scale 0.0 to 0.5 between minimum and competitive
      return 0.5 * (currentGPA - minimumGPA) / (competitiveGPA - minimumGPA);
    } else {
      // Scale 0.5 to 1.0 between competitive and target
      return 0.5 + 0.5 * (currentGPA - competitiveGPA) / (targetGPA - competitiveGPA);
    }
  }

  /// Determines readiness level for this sector
  CareerReadiness getReadiness(double currentGPA) {
    if (currentGPA < minimumGPA) return CareerReadiness.notReady;
    if (currentGPA < competitiveGPA) return CareerReadiness.eligible;
    if (currentGPA < targetGPA) return CareerReadiness.competitive;
    return CareerReadiness.highlyCompetitive;
  }

  factory CareerSector.fromJson(Map<String, dynamic> json) {
    return CareerSector(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      minimumGPA: (json['minimumGPA'] as num).toDouble(),
      competitiveGPA: (json['competitiveGPA'] as num).toDouble(),
      targetGPA: (json['targetGPA'] as num).toDouble(),
      description: json['description'] as String,
      typicalRoles: List<String>.from(json['typicalRoles'] as List),
      region: json['region'] as String? ?? 'Global',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'minimumGPA': minimumGPA,
      'competitiveGPA': competitiveGPA,
      'targetGPA': targetGPA,
      'description': description,
      'typicalRoles': typicalRoles,
      'region': region,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    minimumGPA,
    competitiveGPA,
    targetGPA,
    description,
    typicalRoles,
    region,
  ];
}

enum CareerReadiness {
  notReady, // Below minimum GPA
  eligible, // Meets minimum but not competitive
  competitive, // Meets competitive threshold
  highlyCompetitive, // Meets or exceeds target GPA
}