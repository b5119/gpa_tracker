import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(performanceAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistical Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(performanceAnalysisProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: performanceAsync.when(
            data: (analysis) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PerformanceMetricsCard(analysis: analysis),
                const SizedBox(height: UIConstants.paddingMedium),
                _TrendAnalysisCard(analysis: analysis),
                const SizedBox(height: UIConstants.paddingMedium),
                _ConsistencyCard(analysis: analysis),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(UIConstants.paddingXLarge),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: UIConstants.paddingMedium),
                    Text(
                      'Failed to load analytics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: UIConstants.paddingSmall),
                    Text(error.toString()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Analytics'),
        content: const Text(
          'Statistical analysis of your academic performance including:\n\n'
          '• Mean GPA: Average performance\n'
          '• Standard Deviation: Consistency measure\n'
          '• Trend: Direction of performance\n'
          '• R²: Reliability of trend',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetricsCard extends StatelessWidget {
  final dynamic analysis;

  const _PerformanceMetricsCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            _MetricRow(
              label: 'Mean GPA',
              value: analysis.meanGPA.toStringAsFixed(2),
            ),
            _MetricRow(
              label: 'Standard Deviation',
              value: analysis.standardDeviation.toStringAsFixed(2),
            ),
            _MetricRow(
              label: 'Highest GPA',
              value: analysis.highestGPA.toStringAsFixed(2),
            ),
            _MetricRow(
              label: 'Lowest GPA',
              value: analysis.lowestGPA.toStringAsFixed(2),
            ),
            _MetricRow(
              label: 'GPA Range',
              value: analysis.gpaRange.toStringAsFixed(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendAnalysisCard extends StatelessWidget {
  final dynamic analysis;

  const _TrendAnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final isImproving =
        analysis.trendSlope > StatisticalThresholds.significantTrendSlope;
    final isDeclining =
        analysis.trendSlope < -StatisticalThresholds.significantTrendSlope;

    Color trendColor;
    IconData trendIcon;
    String trendLabel;

    if (isImproving) {
      trendColor = AppColors.improving;
      trendIcon = Icons.trending_up;
      trendLabel = 'Improving Performance';
    } else if (isDeclining) {
      trendColor = AppColors.declining;
      trendIcon = Icons.trending_down;
      trendLabel = 'Declining Performance';
    } else {
      trendColor = AppColors.stable;
      trendIcon = Icons.trending_flat;
      trendLabel = 'Stable Performance';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Container(
              padding: const EdgeInsets.all(UIConstants.paddingMedium),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                border: Border.all(color: trendColor),
              ),
              child: Row(
                children: [
                  Icon(trendIcon, color: trendColor),
                  const SizedBox(width: UIConstants.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trendLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Slope: ${analysis.trendSlope >= 0 ? '+' : ''}${analysis.trendSlope.toStringAsFixed(3)} per semester',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            _MetricRow(
              label: 'R² (Trend Fit)',
              value: analysis.rSquared.toStringAsFixed(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final dynamic analysis;

  const _ConsistencyCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consistency Analysis',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              'Your performance is ${analysis.consistencyRating}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(
              'Based on ${analysis.semesterCount} semesters of data',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
