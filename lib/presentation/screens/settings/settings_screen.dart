import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/student.dart';
import '../settings/grading_system_selector_screen.dart';
import '../../providers/app_providers.dart';
import '../../dialogs/edit_student_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);
    final gradingConfigAsync = ref.watch(gradingConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No student profile found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCreateProfileDialog(context, ref),
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(UIConstants.paddingMedium),
            children: [
              // Profile Section
              _SectionHeader(title: 'Student Profile'),
              _SettingsTile(
                icon: Icons.person,
                title: 'Name',
                subtitle: student.name,
                onTap: () => _showEditStudentDialog(context, ref, student),
              ),
              _SettingsTile(
                icon: Icons.email,
                title: 'Email',
                subtitle: student.email,
                onTap: () => _showEditStudentDialog(context, ref, student),
              ),
              _SettingsTile(
                icon: Icons.school,
                title: 'Program',
                subtitle:
                    '${student.program} (${student.programType.displayName})',
                onTap: () => _showEditStudentDialog(context, ref, student),
              ),
              _SettingsTile(
                icon: Icons.calendar_today,
                title: 'Program Duration',
                subtitle: '${student.programDurationYears} years',
                onTap: () => _showEditStudentDialog(context, ref, student),
              ),

              const SizedBox(height: 24),

              // Academic Settings
              _SectionHeader(title: 'Academic Settings'),
              gradingConfigAsync.when(
                data: (config) {
                  return _SettingsTile(
                    icon: Icons.speed,
                    title: 'GPA Scale',
                    subtitle: config?.name ?? 'Not set',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const GradingSystemSelectorScreen(),
                      ),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              _SettingsTile(
                icon: Icons.replay,
                title: 'Retake Policy',
                subtitle: _getRetakePolicyLabel(student.retakePolicy),
                onTap: () => _showRetakePolicyDialog(context, ref, student),
              ),
              _SettingsTile(
                icon: Icons.confirmation_number,
                title: 'Total Credits Required',
                subtitle: '${student.totalCreditsRequired} credits',
                onTap: () => _showEditStudentDialog(context, ref, student),
              ),

              const SizedBox(height: 24),

              // Data Management
              _SectionHeader(title: 'Data Management'),
              _SettingsTile(
                icon: Icons.download,
                title: 'Export Data',
                subtitle: 'Download your academic records',
                onTap: () => _showExportDialog(context),
              ),
              _SettingsTile(
                icon: Icons.refresh,
                title: 'Reset All Data',
                subtitle: 'Clear all semesters and courses',
                onTap: () => _showResetDialog(context, ref),
                isDestructive: true,
              ),

              const SizedBox(height: 24),

              // App Info
              _SectionHeader(title: 'About'),
              _SettingsTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: AppInfo.appVersion,
                onTap: null,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showEditStudentDialog(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditStudentDialog(student: student),
    );
  }

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CreateStudentDialog(),
    );
  }

  void _showRetakePolicyDialog(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retake Policy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How should retaken courses be calculated?'),
            const SizedBox(height: 16),
            RadioGroup<RetakePolicy>(
              groupValue: student.retakePolicy,
              onChanged: (value) {
                if (value != null) {
                  final updated = student.copyWith(retakePolicy: value);
                  ref
                      .read(currentStudentProvider.notifier)
                      .updateStudent(updated);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...RetakePolicy.values.map((policy) {
                    return RadioListTile<RetakePolicy>(
                      title: Text(_getRetakePolicyLabel(policy)),
                      subtitle: Text(_getRetakePolicyDescription(policy)),
                      value: policy,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your semesters, courses, and academic records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _resetAppData(context, dialogContext, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _getRetakePolicyLabel(RetakePolicy policy) {
    switch (policy) {
      case RetakePolicy.replace:
        return 'Replace (Most Recent)';
      case RetakePolicy.average:
        return 'Average All Attempts';
      case RetakePolicy.best:
        return 'Best Grade';
    }
  }

  String _getRetakePolicyDescription(RetakePolicy policy) {
    switch (policy) {
      case RetakePolicy.replace:
        return 'Only the most recent grade counts';
      case RetakePolicy.average:
        return 'Average of all attempts';
      case RetakePolicy.best:
        return 'Highest grade earned';
    }
  }

  Future<void> _resetAppData(
    BuildContext context,
    BuildContext dialogContext,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(dialogContext);

    try {
      await ref.read(databaseServiceProvider).resetDatabase();
      ref.invalidate(gradingConfigProvider);
      ref.invalidate(currentStudentProvider);
      ref.invalidate(semestersProvider);

      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('All academic data has been reset')),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to reset data: $error')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : null),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
