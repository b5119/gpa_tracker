import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/assessment.dart';
import '../../../domain/models/course.dart';
import '../../dialogs/add_assessment_dialog.dart';
import '../../providers/app_providers.dart';

class CourseAssessmentsScreen extends ConsumerWidget {
  final Course course;
  final String? semesterName;

  const CourseAssessmentsScreen({
    super.key,
    required this.course,
    this.semesterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentsProvider(course.id));
    final gradingConfigAsync = ref.watch(gradingConfigProvider);
    final maxScale = gradingConfigAsync.asData?.value?.maxGPA ?? 4.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(course.courseCode),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(assessmentsProvider(course.id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAssessmentDialog(context, course.id),
        icon: const Icon(Icons.add),
        label: const Text('Add Assessment'),
      ),
      body: SafeArea(
        child: assessmentsAsync.when(
          data: (assessments) {
            final summary = _AssessmentSummary.fromAssessments(assessments);

            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(assessmentsProvider(course.id)),
              child: ListView(
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                children: [
                  _CourseHeaderCard(
                    course: course,
                    semesterName: semesterName,
                    maxScale: maxScale,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  _AssessmentSummaryCard(
                    course: course,
                    summary: summary,
                    maxScale: maxScale,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  Text(
                    'Assessments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingSmall),
                  if (assessments.isEmpty)
                    const _EmptyAssessmentsState()
                  else
                    ...assessments.map(
                      (assessment) => _AssessmentTile(
                        assessment: assessment,
                        onTap: () => _openAssessmentDialog(
                          context,
                          course.id,
                          initial: assessment,
                        ),
                        onDelete: () =>
                            _confirmDeleteAssessment(context, ref, assessment),
                      ),
                    ),
                  const SizedBox(height: UIConstants.paddingXLarge * 2),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.paddingLarge),
              child: Text('Failed to load assessments: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAssessmentDialog(
    BuildContext context,
    String courseId, {
    Assessment? initial,
  }) async {
    await showDialog<Assessment>(
      context: context,
      builder: (_) => AddAssessmentDialog(courseId: courseId, initial: initial),
    );
  }

  Future<void> _confirmDeleteAssessment(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete assessment?'),
        content: Text(
          'Remove ${assessment.name} from ${course.courseCode}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(assessmentsProvider(course.id).notifier)
          .deleteAssessment(assessment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${assessment.name} deleted')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete assessment: $error')),
        );
      }
    }
  }
}

class _CourseHeaderCard extends StatelessWidget {
  final Course course;
  final String? semesterName;
  final double maxScale;

  const _CourseHeaderCard({
    required this.course,
    required this.semesterName,
    required this.maxScale,
  });

  @override
  Widget build(BuildContext context) {
    final transcriptColor = AppColors.getGPAColor(
      course.gradePoint ?? 0.0,
      maxScale: maxScale,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.courseCode,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(course.courseName),
            const SizedBox(height: UIConstants.paddingMedium),
            Wrap(
              spacing: UIConstants.paddingSmall,
              runSpacing: UIConstants.paddingSmall,
              children: [
                Chip(
                  avatar: const Icon(Icons.school_outlined),
                  label: Text('${course.credits} credits'),
                ),
                Chip(
                  avatar: const Icon(Icons.category_outlined),
                  label: Text(course.courseType.name),
                ),
                if (semesterName != null)
                  Chip(
                    avatar: const Icon(Icons.calendar_today_outlined),
                    label: Text(semesterName!),
                  ),
                Chip(
                  avatar: Icon(Icons.grade_outlined, color: transcriptColor),
                  label: Text(
                    course.letterGrade == null
                        ? 'Transcript grade pending'
                        : 'Transcript grade: ${course.letterGrade}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentSummaryCard extends StatelessWidget {
  final Course course;
  final _AssessmentSummary summary;
  final double maxScale;

  const _AssessmentSummaryCard({
    required this.course,
    required this.summary,
    required this.maxScale,
  });

  @override
  Widget build(BuildContext context) {
    final transcriptColor = AppColors.getGPAColor(
      course.gradePoint ?? 0.0,
      maxScale: maxScale,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Progress',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            _MetricRow(
              label: 'Transcript Grade',
              value: course.letterGrade ?? 'Not recorded',
            ),
            _MetricRow(
              label: 'Transcript GPA Points',
              value: course.gradePoint?.toStringAsFixed(2) ?? '--',
              valueColor: transcriptColor,
            ),
            _MetricRow(
              label: 'Assessment Average',
              value: summary.gradedWeight == 0
                  ? 'No graded assessments yet'
                  : '${summary.weightedPercentage.toStringAsFixed(1)}%',
            ),
            _MetricRow(
              label: 'Graded Weight Coverage',
              value: '${summary.gradedWeight.toStringAsFixed(1)}%',
            ),
            if (summary.warning != null) ...[
              const SizedBox(height: UIConstants.paddingMedium),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                ),
                child: Text(summary.warning!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  final Assessment assessment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AssessmentTile({
    required this.assessment,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scoreText = assessment.pointsEarned == null
        ? 'Not graded'
        : '${assessment.pointsEarned!.toStringAsFixed(1)} / ${assessment.totalPoints.toStringAsFixed(1)}';
    final dueDate = assessment.dueDate == null
        ? 'No due date'
        : DateFormat.yMMMd().format(assessment.dueDate!);

    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Icon(_iconForAssessment(assessment.type))),
        title: Text(assessment.name),
        subtitle: Text(
          '$scoreText\n${assessment.weightPercent.toStringAsFixed(1)}% weight • $dueDate',
        ),
        isThreeLine: true,
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete assessment',
        ),
      ),
    );
  }
}

class _EmptyAssessmentsState extends StatelessWidget {
  const _EmptyAssessmentsState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: UIConstants.iconSizeXLarge,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            const Text(
              'No assessments yet. Add quizzes, tests, projects, or exams for this course.',
              textAlign: TextAlign.center,
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
  final Color? valueColor;

  const _MetricRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _AssessmentSummary {
  final double weightedPercentage;
  final double gradedWeight;
  final String? warning;

  const _AssessmentSummary({
    required this.weightedPercentage,
    required this.gradedWeight,
    this.warning,
  });

  factory _AssessmentSummary.fromAssessments(List<Assessment> assessments) {
    final graded = assessments
        .where(
          (assessment) =>
              assessment.pointsEarned != null && assessment.totalPoints > 0,
        )
        .toList();

    if (graded.isEmpty) {
      return const _AssessmentSummary(weightedPercentage: 0, gradedWeight: 0);
    }

    final gradedWeight = graded.fold<double>(
      0,
      (sum, assessment) => sum + assessment.weightPercent,
    );

    double weightedSum = 0;
    for (final assessment in graded) {
      final percent = (assessment.pointsEarned! / assessment.totalPoints) * 100;
      weightedSum += percent * (assessment.weightPercent / 100);
    }

    final normalized = gradedWeight == 0
        ? 0.0
        : weightedSum * (100 / gradedWeight);

    String? warning;
    if ((gradedWeight - 100).abs() > 0.01) {
      warning =
          'Assessment weights with grades currently add up to ${gradedWeight.toStringAsFixed(1)}%, so this average is based on partial course coverage.';
    }

    return _AssessmentSummary(
      weightedPercentage: normalized,
      gradedWeight: gradedWeight,
      warning: warning,
    );
  }
}

IconData _iconForAssessment(AssessmentType type) {
  switch (type) {
    case AssessmentType.assignment:
      return Icons.edit_note;
    case AssessmentType.quiz:
      return Icons.quiz_outlined;
    case AssessmentType.midterm:
      return Icons.rule_folder_outlined;
    case AssessmentType.finalExam:
      return Icons.workspace_premium_outlined;
    case AssessmentType.project:
      return Icons.build_outlined;
  }
}
