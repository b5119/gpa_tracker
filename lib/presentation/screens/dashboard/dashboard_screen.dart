import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/semester.dart';
import '../../dialogs/add_course_dialog.dart';
import '../../dialogs/add_semester_dialog.dart';
import '../../providers/app_providers.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentGPAAsync = ref.watch(currentGPAProvider);
    final semestersAsync = ref.watch(semestersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(semestersProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(semestersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GPA Hero Card
              currentGPAAsync.when(
                data: (gpa) => _GPAHeroCard(gpa: gpa ?? 0.0),
                loading: () => const _LoadingCard(),
                error: (error, _) => _ErrorCard(message: error.toString()),
              ),

              const SizedBox(height: UIConstants.paddingLarge),

              // Quick Stats
              semestersAsync.when(
                data: (semesters) => _QuickStatsSection(semesters: semesters),
                loading: () => const _LoadingCard(),
                error: (error, _) => _ErrorCard(message: error.toString()),
              ),

              const SizedBox(height: UIConstants.paddingLarge),

              // Recent Semesters
              _SectionHeader(
                title: 'Recent Semesters',
                action: TextButton(
                  onPressed: () {
                    semestersAsync.whenData((semesters) {
                      _showAllSemestersSheet(context, ref, semesters);
                    });
                  },
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(height: UIConstants.paddingSmall),

              semestersAsync.when(
                data: (semesters) {
                  if (semesters.isEmpty) {
                    return _EmptyState(
                      icon: Icons.school_outlined,
                      message: 'No semesters yet',
                      actionLabel: 'Add First Semester',
                      onAction: () {
                        _showAddSemesterDialog(context, ref);
                      },
                    );
                  }

                  return Column(
                    children: semesters.reversed.take(3).map((semester) {
                      final semesterGPA = semester.calculateGPA();
                      return _SemesterCard(
                        semesterName: semester.name,
                        gpa: semesterGPA,
                        credits: semester.totalCredits,
                        courseCount: semester.courses.length,
                        onTap: () {
                          _showSemesterDetailsSheet(context, ref, semester);
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const _LoadingCard(),
                error: (error, _) => _ErrorCard(message: error.toString()),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddSemesterDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Semester'),
      ),
    );
  }

  Future<void> _showAddSemesterDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final semester = await showDialog<Semester>(
      context: context,
      builder: (context) => const AddSemesterDialog(),
    );

    if (semester == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${semester.name} added successfully'),
        action: SnackBarAction(
          label: 'Add Course',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AddCourseDialog(semester: semester),
            );
          },
        ),
      ),
    );
  }

  void _showAllSemestersSheet(
    BuildContext context,
    WidgetRef ref,
    List<Semester> semesters,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.paddingMedium),
              child: semesters.isEmpty
                  ? _EmptyState(
                      icon: Icons.school_outlined,
                      message: 'No semesters yet',
                      actionLabel: 'Add First Semester',
                      onAction: () {
                        Navigator.pop(sheetContext);
                        _showAddSemesterDialog(context, ref);
                      },
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Semesters',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: UIConstants.paddingMedium),
                        Expanded(
                          child: ListView(
                            children: semesters.reversed.map((semester) {
                              return _SemesterCard(
                                semesterName: semester.name,
                                gpa: semester.calculateGPA(),
                                credits: semester.totalCredits,
                                courseCount: semester.courses.length,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _showSemesterDetailsSheet(
                                    context,
                                    ref,
                                    semester,
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showSemesterDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    Semester semester,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final gpa = semester.calculateGPA();
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  semester.name,
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Wrap(
                  spacing: UIConstants.paddingSmall,
                  runSpacing: UIConstants.paddingSmall,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.flag_outlined),
                      label: Text(_formatSemesterStatus(semester.status)),
                    ),
                    Chip(
                      avatar: const Icon(Icons.school_outlined),
                      label: Text('${semester.totalCredits} credits'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.book_outlined),
                      label: Text('${semester.courses.length} courses'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.analytics_outlined),
                      label: Text(
                        gpa == null
                            ? 'GPA pending'
                            : 'GPA ${gpa.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          showDialog(
                            context: context,
                            builder: (_) => AddCourseDialog(semester: semester),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Course'),
                      ),
                    ),
                    const SizedBox(width: UIConstants.paddingSmall),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDeleteSemester(context, ref, semester),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingLarge),
                Text(
                  'Courses',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                if (semester.courses.isEmpty)
                  const Text('No courses added to this semester yet.')
                else
                  ...semester.courses.map((course) {
                    final gradeLabel = course.letterGrade ?? 'No grade yet';
                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: UIConstants.paddingSmall,
                      ),
                      child: ListTile(
                        title: Text(course.courseCode),
                        subtitle: Text(
                          '${course.courseName}\n${course.credits} credits • $gradeLabel',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          course.gradePoint?.toStringAsFixed(2) ?? '--',
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSemester(
    BuildContext context,
    WidgetRef ref,
    Semester semester,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Semester?'),
        content: Text(
          'Delete ${semester.name} and all of its courses? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    unawaited(
      ref
          .read(semestersProvider.notifier)
          .deleteSemester(semester.id)
          .then((_) {
            messenger.showSnackBar(
              SnackBar(content: Text('${semester.name} deleted')),
            );
          })
          .catchError((error) {
            messenger.showSnackBar(
              SnackBar(content: Text('Failed to delete semester: $error')),
            );
          }),
    );
  }

  String _formatSemesterStatus(SemesterStatus status) {
    switch (status) {
      case SemesterStatus.upcoming:
        return 'Upcoming';
      case SemesterStatus.inProgress:
        return 'In Progress';
      case SemesterStatus.completed:
        return 'Completed';
    }
  }
}

// =============================================================================
// DASHBOARD WIDGETS
// =============================================================================

class _GPAHeroCard extends StatelessWidget {
  final double gpa;

  const _GPAHeroCard({required this.gpa});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gpaColor = AppColors.getGPAColor(gpa);

    return Card(
      elevation: UIConstants.elevationMedium,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cumulative GPA',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  gpa.toStringAsFixed(2),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: UIConstants.paddingMedium),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.paddingMedium,
                      vertical: UIConstants.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: gpaColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getGPALabel(gpa),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            LinearProgressIndicator(
              value: gpa / GPAScales.scale4Point0,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(gpaColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  String _getGPALabel(double gpa) {
    if (gpa >= GPAScales.deansListMinimum) return "Dean's List";
    if (gpa >= GPAScales.goodStandingMinimum) return 'Good Standing';
    if (gpa >= GPAScales.satisfactoryMinimum) return 'Satisfactory';
    if (gpa >= GPAScales.probationMinimum) return 'Probation';
    return 'At Risk';
  }
}

class _QuickStatsSection extends StatelessWidget {
  final List semesters;

  const _QuickStatsSection({required this.semesters});

  @override
  Widget build(BuildContext context) {
    final totalCredits = semesters.fold<int>(
      0,
      (sum, semester) => sum + (semester.totalCredits as int? ?? 0),
    );

    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            label: 'Total Credits',
            value: totalCredits.toString(),
            icon: Icons.school,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: UIConstants.paddingSmall),
        Expanded(
          child: _QuickStatCard(
            label: 'Semesters',
            value: semesters.length.toString(),
            icon: Icons.calendar_today,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: UIConstants.paddingSmall),
        Expanded(
          child: _QuickStatCard(
            label: 'Courses',
            value: _getTotalCourses(semesters).toString(),
            icon: Icons.book,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  int _getTotalCourses(List semesters) {
    return semesters.fold<int>(
      0,
      (sum, semester) => sum + (semester.courses?.length as int? ?? 0),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          children: [
            Icon(icon, color: color, size: UIConstants.iconSizeLarge),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final String semesterName;
  final double? gpa;
  final int credits;
  final int courseCount;
  final VoidCallback onTap;

  const _SemesterCard({
    required this.semesterName,
    required this.gpa,
    required this.credits,
    required this.courseCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: gpa != null
              ? AppColors.getGPAColor(gpa!)
              : Colors.grey,
          child: Text(
            gpa?.toStringAsFixed(1) ?? '--',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          semesterName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$courseCount courses • $credits credits'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(UIConstants.paddingLarge),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: UIConstants.paddingSmall),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingXLarge),
        child: Column(
          children: [
            Icon(
              icon,
              size: UIConstants.iconSizeXLarge * 2,
              color: Colors.grey,
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
