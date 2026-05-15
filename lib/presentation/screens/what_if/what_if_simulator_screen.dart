import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/models/course.dart';
import '../../../domain/models/semester.dart';
import '../../../domain/services/what_if_simulation_engine.dart';
import '../../providers/app_providers.dart';

class WhatIfSimulatorScreen extends ConsumerStatefulWidget {
  const WhatIfSimulatorScreen({super.key});

  @override
  ConsumerState<WhatIfSimulatorScreen> createState() =>
      _WhatIfSimulatorScreenState();
}

class _WhatIfSimulatorScreenState extends ConsumerState<WhatIfSimulatorScreen> {
  final WhatIfSimulationEngine _simulationEngine = WhatIfSimulationEngine();
  Map<String, double> _simulatedGradePoints = const {};

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semestersProvider);
    final currentGPAAsync = ref.watch(currentGPAProvider);
    final gradingConfigAsync = ref.watch(gradingConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('What-If Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _simulatedGradePoints = const {};
              });
            },
          ),
        ],
      ),
      body: semestersAsync.when(
        data: (semesters) {
          return gradingConfigAsync.when(
            data: (config) {
              final maxGPA = config?.maxGPA ?? GPAScales.scale4Point0;
              _syncSimulationInputs(semesters, maxGPA);

              final courses = semesters
                  .expand(
                    (semester) => semester.courses.map((course) {
                      return _SimulatedCourse(
                        semesterName: semester.name,
                        course: course,
                      );
                    }),
                  )
                  .toList();

              if (courses.isEmpty) {
                return _WhatIfEmptyState(
                  message: 'Add courses to start running grade scenarios.',
                );
              }

              final simulatedGPA = _simulationEngine
                  .calculateSimulatedGpa(_simulatedGradePoints, {
                    for (final item in courses)
                      item.course.id: item.course.credits.toDouble(),
                  });

              return currentGPAAsync.when(
                data: (currentGPA) => ListView(
                  padding: const EdgeInsets.all(UIConstants.paddingMedium),
                  children: [
                    _SimulationSummaryCard(
                      currentGPA: currentGPA,
                      simulatedGPA: simulatedGPA,
                      maxGPA: maxGPA,
                    ),
                    const SizedBox(height: UIConstants.paddingMedium),
                    Text(
                      'Adjust Course Outcomes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: UIConstants.paddingSmall),
                    Text(
                      'Ungraded courses start at 0.0 until you move their slider.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: UIConstants.paddingMedium),
                    ...semesters.map((semester) {
                      final semesterCourses = courses
                          .where(
                            (course) => course.semesterName == semester.name,
                          )
                          .toList();

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: UIConstants.paddingSmall,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(semester.name),
                          subtitle: Text('${semesterCourses.length} courses'),
                          children: semesterCourses.map((item) {
                            final simulatedValue =
                                _simulatedGradePoints[item.course.id] ?? 0.0;

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                UIConstants.paddingMedium,
                                0,
                                UIConstants.paddingMedium,
                                UIConstants.paddingMedium,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.course.courseCode} • ${item.course.courseName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: UIConstants.paddingSmall,
                                  ),
                                  Text(
                                    'Current: ${item.course.gradePoint?.toStringAsFixed(2) ?? '--'} • Simulated: ${simulatedValue.toStringAsFixed(2)}',
                                  ),
                                  Slider(
                                    value: simulatedValue,
                                    min: 0,
                                    max: maxGPA,
                                    divisions: (maxGPA * 10).round(),
                                    label: simulatedValue.toStringAsFixed(2),
                                    onChanged: (value) {
                                      setState(() {
                                        _simulatedGradePoints = {
                                          ..._simulatedGradePoints,
                                          item.course.id: value,
                                        };
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Failed to load GPA data: $error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load grading config: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load semesters: $error')),
      ),
    );
  }

  void _syncSimulationInputs(List<Semester> semesters, double maxGPA) {
    final nextValues = <String, double>{};
    for (final semester in semesters) {
      for (final course in semester.courses) {
        nextValues[course.id] =
            _simulatedGradePoints[course.id] ?? course.gradePoint ?? 0.0;
      }
    }

    if (_mapEquals(_simulatedGradePoints, nextValues)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _simulatedGradePoints = nextValues.map(
          (key, value) => MapEntry(key, value.clamp(0.0, maxGPA)),
        );
      });
    });
  }

  bool _mapEquals(Map<String, double> left, Map<String, double> right) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) return false;
    }
    return true;
  }
}

class _SimulationSummaryCard extends StatelessWidget {
  const _SimulationSummaryCard({
    required this.currentGPA,
    required this.simulatedGPA,
    required this.maxGPA,
  });

  final double? currentGPA;
  final double? simulatedGPA;
  final double maxGPA;

  @override
  Widget build(BuildContext context) {
    final targetGPA = simulatedGPA ?? 0.0;
    return Card(
      elevation: UIConstants.elevationMedium,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'Current GPA',
                value: currentGPA?.toStringAsFixed(2) ?? '--',
              ),
            ),
            Expanded(
              child: _SummaryMetric(
                label: 'Simulated GPA',
                value: simulatedGPA?.toStringAsFixed(2) ?? '--',
                color: AppColors.getGPAColor(targetGPA, maxScale: maxGPA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: UIConstants.paddingSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _WhatIfEmptyState extends StatelessWidget {
  const _WhatIfEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: UIConstants.iconSizeXLarge * 2,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            Text(
              'What-If Simulator',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SimulatedCourse {
  const _SimulatedCourse({required this.semesterName, required this.course});

  final String semesterName;
  final Course course;
}
