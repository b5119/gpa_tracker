import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/assessment.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/usecases/calculate_course_gpa_from_assessments.dart';

// TODO: remove these shims once real providers are introduced.
class AssessmentsNotifier extends StateNotifier<AsyncValue<List<Assessment>>> {
  AssessmentsNotifier() : super(const AsyncValue.data(<Assessment>[]));

  Future<void> deleteAssessment(String assessmentId) async {
    final current = state.maybeWhen(
      data: (items) => items,
      orElse: () => const <Assessment>[],
    );
    state = AsyncValue.data(
      current.where((a) => a.id != assessmentId).toList(),
    );
  }

  Future<void> addAssessment(Assessment assessment) async {
    final current = state.maybeWhen(
      data: (items) => items,
      orElse: () => const <Assessment>[],
    );
    state = AsyncValue.data([...current, assessment]);
  }

  Future<void> updateAssessment(Assessment assessment) async {
    final current = state.maybeWhen(
      data: (items) => items,
      orElse: () => const <Assessment>[],
    );
    state = AsyncValue.data(
      current.map((a) => a.id == assessment.id ? assessment : a).toList(),
    );
  }
}

final assessmentsProvider =
    StateNotifierProvider.family<
      AssessmentsNotifier,
      AsyncValue<List<Assessment>>,
      String
    >((ref, courseId) => AssessmentsNotifier());

final calculateCourseGPAProvider =
    Provider.family<AsyncValue<CourseGPAResult>, String>(
      (ref, courseId) => const AsyncValue.data(
        CourseGPAResult(weightedPercentage: 0, gradePoint: 0),
      ),
    );

class CourseDetailScreen extends ConsumerWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentsProvider(course.id));
    final gradeAsync = ref.watch(calculateCourseGPAProvider(course.id));

    return Scaffold(
      appBar: AppBar(title: Text('${course.code} details')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddAssessment(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: assessmentsAsync.when(
          data: (assessments) {
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(assessmentsProvider(course.id)),
              child: ListView(
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                children: [
                  _CourseHeaderCard(course: course),
                  const SizedBox(height: UIConstants.paddingMedium),
                  gradeAsync.when(
                    data: (gradeResult) => _GradeSummaryCard(
                      percentage: gradeResult.weightedPercentage,
                      letterGrade: _letterFromPercentage(
                        gradeResult.weightedPercentage,
                      ),
                      gradePoint: gradeResult.gradePoint,
                    ),
                    loading: () => const _LoadingCard(),
                    error: (err, _) => _ErrorCard(message: err.toString()),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),
                  if (assessments.isEmpty)
                    const _EmptyAssessmentsState()
                  else
                    ...assessments.map(
                      (assessment) => _AssessmentTile(
                        assessment: assessment,
                        onTap: () =>
                            _onEditAssessment(context, ref, assessment),
                        onDelete: () =>
                            _onDeleteAssessment(context, ref, assessment),
                      ),
                    ),
                  const SizedBox(height: UIConstants.paddingXLarge),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.paddingLarge),
              child: Text(err.toString()),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddAssessment(BuildContext context, WidgetRef ref) async {
    await Navigator.pushNamed(
      context,
      '/assessments/new',
      arguments: {'course': course},
    );
    ref.invalidate(assessmentsProvider(course.id));
    ref.invalidate(calculateCourseGPAProvider(course.id));
  }

  Future<void> _onEditAssessment(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
  ) async {
    await Navigator.pushNamed(
      context,
      '/assessments/edit',
      arguments: {'course': course, 'assessment': assessment},
    );
    ref.invalidate(assessmentsProvider(course.id));
    ref.invalidate(calculateCourseGPAProvider(course.id));
  }

  Future<void> _onDeleteAssessment(
    BuildContext context,
    WidgetRef ref,
    Assessment assessment,
  ) async {
    await ref
        .read(assessmentsProvider(course.id).notifier)
        .deleteAssessment(assessment.id);
    ref.invalidate(calculateCourseGPAProvider(course.id));
  }
}

class _CourseHeaderCard extends StatelessWidget {
  final Course course;

  const _CourseHeaderCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: UIConstants.elevationMedium,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.code,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.paddingSmall),
            Text(course.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: UIConstants.paddingSmall),
            Row(
              children: [
                const Icon(Icons.schedule, size: UIConstants.iconSizeMedium),
                const SizedBox(width: UIConstants.paddingSmall),
                Text('${course.creditUnits} credit hours'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeSummaryCard extends StatelessWidget {
  final double percentage;
  final String letterGrade;
  final double gradePoint;

  const _GradeSummaryCard({
    required this.percentage,
    required this.letterGrade,
    required this.gradePoint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.getGPAColor(gradePoint);
    return Card(
      elevation: UIConstants.elevationHigh,
      child: Container(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Grade',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: UIConstants.paddingSmall),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Chip(
                        backgroundColor: color,
                        label: Text(
                          letterGrade,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Text(
                  'Grade points: ${gradePoint.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
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
    final theme = Theme.of(context);
    final score = assessment.pointsEarned;
    final scoreText = score == null
        ? 'Not graded'
        : '${score.toStringAsFixed(1)} / ${assessment.totalPoints.toStringAsFixed(1)} points';
    final weightText =
        '${assessment.weightPercent.toStringAsFixed(1)}% of grade';
    final dueDateText = assessment.dueDate != null
        ? DateFormat.yMMMd().format(assessment.dueDate!)
        : null;

    return Dismissible(
      key: ValueKey(assessment.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete assessment?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ==
            true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.paddingLarge,
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: UIConstants.elevationLow,
        margin: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              _iconForAssessment(assessment.type),
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(assessment.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scoreText),
              Text(weightText),
              if (dueDateText != null) Text('Due: $dueDateText'),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _EmptyAssessmentsState extends StatelessWidget {
  const _EmptyAssessmentsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in,
            size: UIConstants.iconSizeXLarge,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: UIConstants.paddingMedium),
          Text(
            'No assessments yet - tap + to add',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Text(message),
      ),
    );
  }
}

IconData _iconForAssessment(AssessmentType type) {
  switch (type) {
    case AssessmentType.assignment:
      return Icons.assignment;
    case AssessmentType.quiz:
      return Icons.quiz;
    case AssessmentType.midterm:
      return Icons.article;
    case AssessmentType.finalExam:
      return Icons.school;
    case AssessmentType.project:
      return Icons.build;
  }
}

String _letterFromPercentage(double percent) {
  if (percent >= 90) return 'A';
  if (percent >= 80) return 'B';
  if (percent >= 70) return 'C';
  if (percent >= 60) return 'D';
  return 'F';
}
