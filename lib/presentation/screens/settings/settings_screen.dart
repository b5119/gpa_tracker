import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/student.dart';
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
                    onTap: () => _showGPAScaleDialog(context, ref, config),
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

  void _showGPAScaleDialog(BuildContext context, WidgetRef ref, gradingConfig) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select GPA Scale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('4.0 Scale'),
              subtitle: const Text('Standard US system'),
              leading: Radio<String>(
                value: 'us_4_0_standard',
                groupValue: gradingConfig?.id,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(gradingConfigProvider.notifier)
                        .setActiveConfig(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('5.0 Scale'),
              subtitle: const Text('Some universities'),
              leading: Radio<String>(
                value: 'us_5_0_standard',
                groupValue: gradingConfig?.id,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(gradingConfigProvider.notifier)
                        .setActiveConfig(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
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
            ...RetakePolicy.values.map((policy) {
              return RadioListTile<RetakePolicy>(
                title: Text(_getRetakePolicyLabel(policy)),
                subtitle: Text(_getRetakePolicyDescription(policy)),
                value: policy,
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
              );
            }).toList(),
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
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your semesters, courses, and academic records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset functionality coming soon'),
                ),
              );
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
