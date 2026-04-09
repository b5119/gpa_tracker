import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/grading_config.dart';
import '../../providers/app_providers.dart';

/// Screen that lets users pick the active grading system (4.0, 5.0, or custom).
class GradingSystemSelectorScreen extends ConsumerWidget {
  const GradingSystemSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeConfigAsync = ref.watch(gradingConfigProvider);
    final configsAsync = ref.watch(_gradingConfigsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Grading Systems')),
      body: configsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'Unable to load grading systems',
          onRetry: () => ref.invalidate(_gradingConfigsProvider),
        ),
        data: (configs) {
          final activeConfig = activeConfigAsync.asData?.value;
          final activeId = activeConfig?.id;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_gradingConfigsProvider);
              await Future.sync(
                () => ref.read(gradingConfigProvider.notifier).refresh(),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(UIConstants.paddingLarge),
              children: [
                const Text(
                  'Select your university\'s grading system',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                ...configs.map(
                  (config) => _ConfigCard(
                    config: config,
                    isActive: config.id == activeId,
                    onPreview: () => _showMapping(context, config),
                    onSetActive: () => _confirmChange(context, ref, config),
                  ),
                ),
                const SizedBox(height: UIConstants.paddingLarge),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCustomComingSoon(context),
                  label: const Text('Create Custom Grading System'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmChange(
    BuildContext context,
    WidgetRef ref,
    GradingConfig config,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set as active?'),
        content: const Text(
          'Changing the grading system will update GPA calculations for existing courses. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, change'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(gradingConfigProvider.notifier).setActiveConfig(config.id);
      ref.invalidate(_gradingConfigsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${config.name} set as active')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change grading system: $error')),
        );
      }
    }
  }

  void _showMapping(BuildContext context, GradingConfig config) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${config.name} (${config.maxGPA.toStringAsFixed(1)} scale)',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            ...config.gradeToPointMap.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: UIConstants.paddingSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(entry.value.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom grading system creation coming soon'),
      ),
    );
  }
}

final _gradingConfigsProvider = FutureProvider<List<GradingConfig>>((
  ref,
) async {
  final repository = ref.read(gradingConfigRepositoryProvider);
  await repository.initializeDefaults();
  final configs = await repository.getAllConfigs();

  configs.sort((a, b) {
    // Default systems first, then newest
    if (a.isDefault != b.isDefault) {
      return a.isDefault ? -1 : 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  });

  return configs;
});

class _ConfigCard extends StatelessWidget {
  final GradingConfig config;
  final bool isActive;
  final VoidCallback onPreview;
  final VoidCallback onSetActive;

  const _ConfigCard({
    required this.config,
    required this.isActive,
    required this.onPreview,
    required this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    final sampleGrades = config.gradeToPointMap.entries.take(4).toList();
    final tone = Theme.of(context).colorScheme;

    return Card(
      color: isActive ? tone.secondaryContainer : null,
      elevation: UIConstants.elevationLow,
      margin: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
      child: InkWell(
        onTap: onPreview,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: UIConstants.paddingSmall),
                        Text(
                          '${_systemLabel(config.systemType)} · Max ${config.maxGPA.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Radio<bool>(
                    value: true,
                    groupValue: isActive,
                    onChanged: (_) => onSetActive(),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.paddingSmall),
              Wrap(
                spacing: UIConstants.paddingSmall,
                runSpacing: UIConstants.paddingSmall,
                children: sampleGrades
                    .map(
                      (e) => Chip(
                        label: Text('${e.key} = ${e.value.toStringAsFixed(1)}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: UIConstants.paddingMedium),
              Row(
                children: [
                  TextButton(
                    onPressed: onPreview,
                    child: const Text('Preview full mapping'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onSetActive,
                    child: Text(isActive ? 'Active' : 'Set as active'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _systemLabel(GradingSystemType type) {
    switch (type) {
      case GradingSystemType.points4_0:
        return 'US 4.0 Scale';
      case GradingSystemType.points5_0:
        return 'US 5.0 Scale';
      case GradingSystemType.percentage:
        return 'Percentage';
      case GradingSystemType.letterOnly:
        return 'Letter Only';
      case GradingSystemType.custom:
        return 'Custom';
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: UIConstants.paddingMedium),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
