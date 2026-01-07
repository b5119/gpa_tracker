import 'package:equatable/equatable.dart';

class CareerSector extends Equatable {
  final String id;
  final String name;
  final String category;
  final double minimumGPA;
  final double competitiveGPA;
  final double targetGPA;
  final String description;
  final List<String> typicalRoles;
  final String region;

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

  double calculateFitScore(double currentGPA) {
    if (currentGPA < minimumGPA) return 0.0;
    if (currentGPA >= targetGPA) return 1.0;

    if (currentGPA < competitiveGPA) {
      return 0.5 * (currentGPA - minimumGPA) / (competitiveGPA - minimumGPA);
    } else {
      return 0.5 + 0.5 * (currentGPA - competitiveGPA) / (targetGPA - competitiveGPA);
    }
  }

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
  notReady,
  eligible,
  competitive,
  highlyCompetitive,
}