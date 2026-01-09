import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
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
  final _creditsController = TextEditingController(text: '3');

  String? _selectedLetterGrade;
  double? _gradePoint;
  CourseType _courseType = CourseType.major;
  int _attemptNumber = 1;

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(currentStudentProvider);

    return studentAsync.when(
      data: (student) {
        if (student == null) return const SizedBox();

        return AlertDialog(
          title: Text('Add Course to ${widget.semester.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _courseCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Course Code *',
                      prefixIcon: Icon(Icons.code),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., CS101',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter course code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _courseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Course Name *',
                      prefixIcon: Icon(Icons.book),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Introduction to Programming',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter course name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _creditsController,
                          decoration: const InputDecoration(
                            labelText: 'Credits *',
                            prefixIcon: Icon(Icons.confirmation_number),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final credits = int.tryParse(value);
                            if (credits == null ||
                                credits < AcademicConstants.minCreditsPerCourse ||
                                credits > AcademicConstants.maxCreditsPerCourse) {
                              return '1-6';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<CourseType>(
                          value: _courseType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: CourseType.major, child: Text('Major')),
                            DropdownMenuItem(value: CourseType.minor, child: Text('Minor')),
                            DropdownMenuItem(value: CourseType.elective, child: Text('Elective')),
                            DropdownMenuItem(value: CourseType.general, child: Text('General Ed')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _courseType = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Grade (leave empty if in progress)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedLetterGrade,
                    decoration: const InputDecoration(
                      labelText: 'Letter Grade',
                      prefixIcon: Icon(Icons.grade),
                      border: OutlineInputBorder(),
                    ),
                    items: GPAScales.letterGrades.map((grade) {
                      final points = student.gpaScale == 4.0
                          ? GPAScales.gradePoints4_0[grade]
                          : GPAScales.gradePoints5_0[grade];
                      return DropdownMenuItem(
                        value: grade,
                        child: Text('$grade (${points?.toStringAsFixed(1)})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLetterGrade = value;
                        if (value != null) {
                          _gradePoint = student.gpaScale == 4.0
                              ? GPAScales.gradePoints4_0[value]
                              : GPAScales.gradePoints5_0[value];
                        } else {
                          _gradePoint = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_gradePoint != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getGPAColor(_gradePoint!, maxScale: student.gpaScale)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.getGPAColor(_gradePoint!, maxScale: student.gpaScale),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.getGPAColor(_gradePoint!, maxScale: student.gpaScale),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Grade Point: ${_gradePoint!.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Check for existing course attempts
                  if (_hasPreviousAttempts())
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This appears to be a retake. Attempt #$_attemptNumber',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => addCourse(student.gpaScale),
              child: const Text('Add Course'),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox(),
    );
  }

  bool _hasPreviousAttempts() {
    final courseCode = _courseCodeController.text.trim().toUpperCase();
    if (courseCode.isEmpty) return false;

    // Add your logic here to check for previous attempts
    // This is incomplete in the original code
    return false;
  }

  void addCourse(double gpaScale) {
    if (_formKey.currentState!.validate()) {
      // Add your course creation logic here
      Navigator.pop(context);
    }
  }
}