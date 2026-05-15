import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/usecases/predict_future_gpa.dart';
import '../../providers/app_providers.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(gpaPredictionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GPA Predictions')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gpaPredictionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: predictionAsync.when(
            data: (prediction) {
              if (prediction.basedOnSemesters == 0) {
                return _PredictionEmptyState(
                  message: prediction.recommendations.first,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PredictionHeroCard(prediction: prediction),
                  const SizedBox(height: UIConstants.paddingMedium),
                  _PredictionRangeCard(prediction: prediction),
                  const SizedBox(height: UIConstants.paddingMedium),
                  _PredictionListCard(
                    title: 'Risk Flags',
                    icon: Icons.warning_amber_rounded,
                    items: prediction.riskFlags.isEmpty
                        ? const ['No immediate forecast risks detected']
                        : prediction.riskFlags,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  _PredictionListCard(
                    title: 'Recommendations',
                    icon: Icons.task_alt,
                    items: prediction.recommendations,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  _PredictionMethodCard(prediction: prediction),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(UIConstants.paddingXLarge),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.paddingLarge),
                child: Text('Failed to load predictions: $error'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PredictionHeroCard extends StatelessWidget {
  const _PredictionHeroCard({required this.prediction});

  final PredictionResult prediction;

  @override
  Widget build(BuildContext context) {
    final projectedColor = AppColors.getGPAColor(prediction.projectedFinalGPA);
    return Card(
      elevation: UIConstants.elevationMedium,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
          gradient: LinearGradient(
            colors: [
              projectedColor.withValues(alpha: 0.18),
              Theme.of(context).colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projected Final GPA',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Row(
              children: [
                Text(
                  prediction.projectedFinalGPA.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: projectedColor,
                  ),
                ),
                const Spacer(),
                Chip(
                  backgroundColor: projectedColor,
                  label: Text(
                    _confidenceLabel(prediction.confidenceLevel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(
              'Based on ${prediction.basedOnSemesters} completed semesters with ${prediction.remainingSemesters} semesters remaining.',
            ),
          ],
        ),
      ),
    );
  }

  String _confidenceLabel(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 'High Confidence';
      case ConfidenceLevel.medium:
        return 'Medium Confidence';
      case ConfidenceLevel.low:
        return 'Low Confidence';
    }
  }
}

class _PredictionRangeCard extends StatelessWidget {
  const _PredictionRangeCard({required this.prediction});

  final PredictionResult prediction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Range',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            _MetricRow(
              label: 'Best Case',
              value: prediction.bestCaseGPA.toStringAsFixed(2),
            ),
            _MetricRow(
              label: 'Expected',
              value: prediction.projectedFinalGPA.toStringAsFixed(2),
            ),
            _MetricRow(
              label: 'Worst Case',
              value: prediction.worstCaseGPA.toStringAsFixed(2),
            ),
            _MetricRow(
              label: 'Confidence Score',
              value:
                  '${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
            ),
            _MetricRow(
              label: 'Credits Still In Play',
              value: '${(prediction.impactFactor * 100).toStringAsFixed(0)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionListCard extends StatelessWidget {
  const _PredictionListCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: UIConstants.paddingSmall),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: UIConstants.paddingSmall),
                child: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionMethodCard extends StatelessWidget {
  const _PredictionMethodCard({required this.prediction});

  final PredictionResult prediction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Methodology',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(prediction.methodology),
          ],
        ),
      ),
    );
  }
}

class _PredictionEmptyState extends StatelessWidget {
  const _PredictionEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.paddingXLarge),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: UIConstants.iconSizeXLarge * 2,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: UIConstants.paddingLarge),
          Text(
            'Not enough data for a prediction yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: UIConstants.paddingMedium),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
