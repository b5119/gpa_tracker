import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

class CareerIntelligenceScreen extends ConsumerWidget {
  const CareerIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careerFitAsync = ref.watch(careerFitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Intelligence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showScoringInfo(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(careerFitProvider);
        },
        child: careerFitAsync.when(
          data: (report) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(UIConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OverallAssessmentCard(
                  currentGPA: report.currentGPA,
                  assessment: report.overallAssessment,
                  competitiveSectors: report.totalCompetitiveSectors,
                  reachableSectors: report.totalReachableSectors,
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                Text(
                  'Top Recommendations',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                ...report.topRecommendations.map((analysis) {
                  return _SectorCard(analysis: analysis);
                }).toList(),
                const SizedBox(height: UIConstants.paddingMedium),
                Text(
                  'All Sectors',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                ...report.allSectors.map((analysis) {
                  return _SectorCard(analysis: analysis);
                }).toList(),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: UIConstants.paddingMedium),
                Text(error.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScoringInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Career Scoring'),
        content: const Text(
          'Career recommendations are ranked from your current GPA and the active grading system. Improve your GPA or switch grading scales in Settings to see how the rankings change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _OverallAssessmentCard extends StatelessWidget {
  final double currentGPA;
  final String assessment;
  final int competitiveSectors;
  final int reachableSectors;

  const _OverallAssessmentCard({
    required this.currentGPA,
    required this.assessment,
    required this.competitiveSectors,
    required this.reachableSectors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Current GPA: ${currentGPA.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.paddingMedium,
                    vertical: UIConstants.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getGPAColor(currentGPA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getGPATier(currentGPA),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(assessment, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: UIConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Competitive',
                    value: competitiveSectors.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: UIConstants.paddingSmall),
                Expanded(
                  child: _StatChip(
                    label: 'Reachable',
                    value: reachableSectors.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGPATier(double gpa) {
    if (gpa >= 3.7) return 'Excellent';
    if (gpa >= 3.3) return 'Very Good';
    if (gpa >= 3.0) return 'Good';
    if (gpa >= 2.5) return 'Fair';
    return 'Below Average';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  final dynamic analysis;

  const _SectorCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final sector = analysis.sector;
    final fitScore = analysis.fitScore;
    final readiness = analysis.readiness.toString().split('.').last;
    Color readinessColor;
    switch (readiness) {
      case 'highlyCompetitive':
        readinessColor = AppColors.highlyCompetitive;
        break;
      case 'competitive':
        readinessColor = AppColors.competitive;
        break;
      case 'eligible':
        readinessColor = AppColors.eligible;
        break;
      default:
        readinessColor = AppColors.notReady;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: readinessColor,
          child: Text(
            '${(fitScore * 100).toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          sector.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(sector.category),
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sector.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                _GPARequirement(
                  label: 'Minimum',
                  gpa: sector.minimumGPA,
                  color: Colors.red,
                ),
                _GPARequirement(
                  label: 'Competitive',
                  gpa: sector.competitiveGPA,
                  color: Colors.orange,
                ),
                _GPARequirement(
                  label: 'Target',
                  gpa: sector.targetGPA,
                  color: Colors.green,
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sector.typicalRoles.map<Widget>((role) {
                    return Chip(
                      label: Text(role),
                      labelStyle: const TextStyle(fontSize: 12),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GPARequirement extends StatelessWidget {
  final String label;
  final double gpa;
  final Color color;
  const _GPARequirement({
    required this.label,
    required this.gpa,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${gpa.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
