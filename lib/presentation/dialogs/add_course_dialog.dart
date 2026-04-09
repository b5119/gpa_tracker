import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/grading_config.dart';
import '../../domain/models/course.dart';
import '../../domain/models/semester.dart';
import '../providers/app_providers.dart';

class AddCourseDialog extends ConsumerStatefulWidget {
  final Semester semester;

  const AddCourseDialog({super.key, required this.semester});

  @override
  ConsumerState<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends ConsumerState<AddCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  int _credits = AcademicConstants.typicalCreditsPerCourse;
  CourseType _courseType = CourseType.core;
  int _attemptNumber = 1;
  GradingOption _gradingOption = GradingOption.letter;
  String? _selectedLetterGrade;
  String? _passFailSelection;
  double? _gradePoint;

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(currentStudentProvider);
    final gradingConfigAsync = ref.watch(gradingConfigProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingMedium,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: studentAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(UIConstants.paddingLarge),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Text('Error loading student: $e'),
          ),
          data: (student) {
            if (student == null) {
              return const Padding(
                padding: EdgeInsets.all(UIConstants.paddingLarge),
                child: Text('No student found'),
              );
            }

            return gradingConfigAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(UIConstants.paddingLarge),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(UIConstants.paddingLarge),
                child: Text('Error loading grading config: $e'),
              ),
              data: (config) {
                final letterGrades =
                    config?.availableGrades ?? GPAScales.letterGrades;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(UIConstants.paddingLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Add Course to ${widget.semester.name}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: UIConstants.paddingMedium),

                        _buildDetailsCard(),
                        const SizedBox(height: UIConstants.paddingMedium),
                        _buildGradingCard(
                          letterGrades,
                          config,
                          student.gpaScale,
                        ),
                        const SizedBox(height: UIConstants.paddingLarge),

                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: UIConstants.paddingSmall),
                            Expanded(
                              child: FilledButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Save Course'),
                                onPressed: () =>
                                    _saveCourse(config, student.gpaScale),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: UIConstants.elevationLow,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: UIConstants.paddingMedium),

            TextFormField(
              controller: _courseCodeController,
              decoration: const InputDecoration(
                labelText: 'Course Code *',
                prefixIcon: Icon(Icons.code),
                hintText: 'e.g., CS101, MATH240',
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                UpperCaseTextFormatter(),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Course code is required';
                }
                if (value.trim().length < 3) {
                  return 'Enter a valid course code';
                }
                return null;
              },
            ),
            const SizedBox(height: UIConstants.paddingMedium),

            TextFormField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Course Name *',
                prefixIcon: Icon(Icons.book),
                hintText: 'e.g., Introduction to Programming',
              ),
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Course name is required';
                }
                if (value.trim().length > 200) {
                  return 'Max 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: UIConstants.paddingSmall),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _credits,
                    decoration: const InputDecoration(
                      labelText: 'Credits *',
                      prefixIcon: Icon(Icons.confirmation_num),
                    ),
                    items: List.generate(6, (i) => i + 1)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _credits = value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value < 1 || value > 6) {
                        return 'Select 1-6 credits';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: UIConstants.paddingMedium),
                Expanded(
                  child: DropdownButtonFormField<CourseType>(
                    value: _courseType,
                    decoration: const InputDecoration(
                      labelText: 'Course Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: CourseType.core,
                        child: Text('Core'),
                      ),
                      DropdownMenuItem(
                        value: CourseType.elective,
                        child: Text('Elective'),
                      ),
                      DropdownMenuItem(
                        value: CourseType.general,
                        child: Text('General Education'),
                      ),
                      DropdownMenuItem(
                        value: CourseType.major,
                        child: Text('Major'),
                      ),
                      DropdownMenuItem(
                        value: CourseType.minor,
                        child: Text('Minor'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _courseType = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingMedium),

            DropdownButtonFormField<int>(
              value: _attemptNumber,
              decoration: const InputDecoration(
                labelText: 'Attempt Number',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: List.generate(3, (i) => i + 1)
                  .map(
                    (n) =>
                        DropdownMenuItem(value: n, child: Text('Attempt $n')),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _attemptNumber = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradingCard(
    List<String> letterGrades,
    GradingConfig? config,
    double gpaScale,
  ) {
    return Card(
      elevation: UIConstants.elevationLow,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grading', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: UIConstants.paddingMedium),
            DropdownButtonFormField<GradingOption>(
              value: _gradingOption,
              decoration: const InputDecoration(
                labelText: 'Grading Option',
                prefixIcon: Icon(Icons.grade),
              ),
              items: const [
                DropdownMenuItem(
                  value: GradingOption.letter,
                  child: Text('Letter Grade'),
                ),
                DropdownMenuItem(
                  value: GradingOption.passFail,
                  child: Text('Pass/Fail'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _gradingOption = value;
                    _selectedLetterGrade = null;
                    _passFailSelection = null;
                    _gradePoint = null;
                  });
                }
              },
            ),
            const SizedBox(height: UIConstants.paddingMedium),

            if (_gradingOption == GradingOption.letter)
              DropdownButtonFormField<String>(
                value: _selectedLetterGrade,
                decoration: const InputDecoration(
                  labelText: 'Letter Grade',
                  prefixIcon: Icon(Icons.emoji_events),
                ),
                items: letterGrades
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(_gradeLabel(g, config)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLetterGrade = value;
                    _gradePoint = _toGradePoint(value, config, gpaScale);
                  });
                },
                validator: (value) {
                  if (_gradingOption == GradingOption.letter &&
                      (value == null || value.isEmpty)) {
                    return 'Select a letter grade';
                  }
                  return null;
                },
              ),

            if (_gradingOption == GradingOption.passFail)
              DropdownButtonFormField<String>(
                value: _passFailSelection,
                decoration: const InputDecoration(
                  labelText: 'Result',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'Pass', child: Text('Pass')),
                  DropdownMenuItem(value: 'Fail', child: Text('Fail')),
                ],
                onChanged: (value) {
                  setState(() {
                    _passFailSelection = value;
                    _gradePoint = value == 'Pass' ? gpaScale : 0.0;
                  });
                },
                validator: (value) {
                  if (_gradingOption == GradingOption.passFail &&
                      (value == null || value.isEmpty)) {
                    return 'Select Pass or Fail';
                  }
                  return null;
                },
              ),

            if (_gradePoint != null)
              Padding(
                padding: const EdgeInsets.only(top: UIConstants.paddingMedium),
                child: _GradePreview(
                  gradePoint: _gradePoint!,
                  maxScale: gpaScale,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _gradeLabel(String grade, GradingConfig? config) {
    final gp = _toGradePoint(grade, config, config?.maxGPA ?? 4.0);
    if (gp == null) return grade;
    return '$grade (${gp.toStringAsFixed(1)})';
  }

  double? _toGradePoint(String? grade, GradingConfig? config, double gpaScale) {
    if (grade == null) return null;
    if (config != null) return config.getGradePoint(grade);
    return gpaScale == 4.0
        ? GPAScales.gradePoints4_0[grade]
        : GPAScales.gradePoints5_0[grade];
  }

  Future<void> _saveCourse(GradingConfig? config, double gpaScale) async {
    if (!_formKey.currentState!.validate()) return;

    if (_gradingOption == GradingOption.letter &&
        _selectedLetterGrade == null) {
      return;
    }
    if (_gradingOption == GradingOption.passFail &&
        _passFailSelection == null) {
      return;
    }

    final course = Course(
      id: 'course_${DateTime.now().millisecondsSinceEpoch}',
      semesterId: widget.semester.id,
      courseCode: _courseCodeController.text.trim().toUpperCase(),
      courseName: _courseNameController.text.trim(),
      credits: _credits,
      letterGrade: _gradingOption == GradingOption.letter
          ? _selectedLetterGrade
          : _passFailSelection,
      gradePoint: _gradingOption == GradingOption.letter
          ? _toGradePoint(_selectedLetterGrade, config, gpaScale)
          : (_passFailSelection == 'Pass' ? gpaScale : 0.0),
      attemptNumber: _attemptNumber,
      courseType: _courseType,
    );

    await ref
        .read(semestersProvider.notifier)
        .updateSemester(
          widget.semester.copyWith(
            courses: [...widget.semester.courses, course],
          ),
        );

    if (!mounted) return;
    Navigator.pop(context, course);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Course ${course.courseCode} added')),
    );
  }
}

class _GradePreview extends StatelessWidget {
  final double gradePoint;
  final double maxScale;

  const _GradePreview({required this.gradePoint, required this.maxScale});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getGPAColor(gradePoint, maxScale: maxScale);
    return Container(
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, color: color),
          const SizedBox(width: UIConstants.paddingSmall),
          Text(
            'Grade Point Preview: ${gradePoint.toStringAsFixed(2)} / ${maxScale.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

enum GradingOption { letter, passFail }
