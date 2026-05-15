import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/student.dart';
import '../providers/app_providers.dart';

class EditStudentDialog extends ConsumerStatefulWidget {
  final Student student;

  const EditStudentDialog({super.key, required this.student});

  @override
  ConsumerState<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends ConsumerState<EditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _programController;
  late TextEditingController _creditsController;
  late TextEditingController _durationController;
  late DateTime _enrollmentDate;
  late double _gpaScale;
  late RetakePolicy _retakePolicy;
  late ProgramType _programType;
  late int _programDurationYears;
  late AcademicTerm _startTerm;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _emailController = TextEditingController(text: widget.student.email);
    _programController = TextEditingController(text: widget.student.program);
    _creditsController = TextEditingController(
      text: widget.student.totalCreditsRequired.toString(),
    );
    _durationController = TextEditingController(
      text: widget.student.programDurationYears.toString(),
    );
    _enrollmentDate = widget.student.enrollmentDate;
    _gpaScale = widget.student.gpaScale;
    _retakePolicy = widget.student.retakePolicy;
    _programType = widget.student.programType;
    _programDurationYears = widget.student.programDurationYears;
    _startTerm = widget.student.startTerm;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _programController.dispose();
    _creditsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Student Profile'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Section
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!ValidationConstants.emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Program Information Section
                const Text(
                  'Program Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _programController,
                  decoration: const InputDecoration(
                    labelText: 'Program/Major',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Computer Science',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your program';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<ProgramType>(
                  initialValue: _programType,
                  decoration: const InputDecoration(
                    labelText: 'Program Type',
                    prefixIcon: Icon(Icons.workspace_premium),
                    border: OutlineInputBorder(),
                  ),
                  items: ProgramType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _programType = value;
                        _programDurationYears = value.typicalDurationYears;
                        _durationController.text = _programDurationYears
                            .toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Program Duration (Years)',
                    prefixIcon: Icon(Icons.timelapse),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 4',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter program duration';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0 || duration > 10) {
                      return 'Please enter a valid duration (1-10 years)';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final duration = int.tryParse(value);
                    if (duration != null) {
                      setState(() => _programDurationYears = duration);
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _creditsController,
                  decoration: const InputDecoration(
                    labelText: 'Total Credits Required',
                    prefixIcon: Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 120',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter required credits';
                    }
                    final credits = int.tryParse(value);
                    if (credits == null || credits <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Enrollment Details Section
                const Text(
                  'Enrollment Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Enrollment Date'),
                  subtitle: Text(_formatDate(_enrollmentDate)),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectEnrollmentDate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<AcademicTerm>(
                  initialValue: _startTerm,
                  decoration: const InputDecoration(
                    labelText: 'Starting Term',
                    prefixIcon: Icon(Icons.event_available),
                    border: OutlineInputBorder(),
                  ),
                  items: AcademicTerm.values.map((term) {
                    return DropdownMenuItem(
                      value: term,
                      child: Text(term.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _startTerm = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Grading Configuration Section
                const Text(
                  'Grading Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<double>(
                  initialValue: _gpaScale,
                  decoration: const InputDecoration(
                    labelText: 'GPA Scale',
                    prefixIcon: Icon(Icons.speed),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 4.0,
                      child: Text('4.0 Scale (Standard)'),
                    ),
                    DropdownMenuItem(value: 5.0, child: Text('5.0 Scale')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _gpaScale = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<RetakePolicy>(
                  initialValue: _retakePolicy,
                  decoration: const InputDecoration(
                    labelText: 'Retake Policy',
                    prefixIcon: Icon(Icons.replay),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: RetakePolicy.replace,
                      child: Text('Replace (Most Recent)'),
                    ),
                    DropdownMenuItem(
                      value: RetakePolicy.average,
                      child: Text('Average All Attempts'),
                    ),
                    DropdownMenuItem(
                      value: RetakePolicy.best,
                      child: Text('Best Grade'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _retakePolicy = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveStudent, child: const Text('Save')),
      ],
    );
  }

  Future<void> _selectEnrollmentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _enrollmentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _enrollmentDate = picked);
    }
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      final updatedStudent = widget.student.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        program: _programController.text.trim(),
        programType: _programType,
        programDurationYears: int.parse(_durationController.text),
        totalCreditsRequired: int.parse(_creditsController.text),
        enrollmentDate: _enrollmentDate,
        startTerm: _startTerm,
        gpaScale: _gpaScale,
        retakePolicy: _retakePolicy,
      );

      ref.read(currentStudentProvider.notifier).updateStudent(updatedStudent);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

// Create new student dialog
class CreateStudentDialog extends ConsumerStatefulWidget {
  const CreateStudentDialog({super.key});

  @override
  ConsumerState<CreateStudentDialog> createState() =>
      _CreateStudentDialogState();
}

class _CreateStudentDialogState extends ConsumerState<CreateStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _programController = TextEditingController();
  final _creditsController = TextEditingController(text: '120');
  final _durationController = TextEditingController(text: '4');
  DateTime _enrollmentDate = DateTime.now();
  double _gpaScale = 4.0;
  RetakePolicy _retakePolicy = RetakePolicy.replace;
  ProgramType _programType = ProgramType.bachelors;
  int _programDurationYears = 4;
  AcademicTerm _startTerm = AcademicTerm.fall;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _programController.dispose();
    _creditsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Student Profile'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set up your academic profile to get started',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Personal Information
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!ValidationConstants.emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _programController,
                  decoration: const InputDecoration(
                    labelText: 'Program/Major *',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Computer Science',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your program';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<ProgramType>(
                  initialValue: _programType,
                  decoration: const InputDecoration(
                    labelText: 'Program Type *',
                    prefixIcon: Icon(Icons.workspace_premium),
                    border: OutlineInputBorder(),
                  ),
                  items: ProgramType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _programType = value;
                        _programDurationYears = value.typicalDurationYears;
                        _durationController.text = _programDurationYears
                            .toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Program Duration (Years) *',
                    prefixIcon: Icon(Icons.timelapse),
                    border: OutlineInputBorder(),
                    hintText: '4',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter program duration';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0 || duration > 10) {
                      return 'Please enter a valid duration (1-10 years)';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final duration = int.tryParse(value);
                    if (duration != null) {
                      setState(() => _programDurationYears = duration);
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _creditsController,
                  decoration: const InputDecoration(
                    labelText: 'Total Credits Required *',
                    prefixIcon: Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(),
                    hintText: '120',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter required credits';
                    }
                    final credits = int.tryParse(value);
                    if (credits == null || credits <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<AcademicTerm>(
                  initialValue: _startTerm,
                  decoration: const InputDecoration(
                    labelText: 'Starting Term *',
                    prefixIcon: Icon(Icons.event_available),
                    border: OutlineInputBorder(),
                  ),
                  items: AcademicTerm.values.map((term) {
                    return DropdownMenuItem(
                      value: term,
                      child: Text(term.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _startTerm = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<double>(
                  initialValue: _gpaScale,
                  decoration: const InputDecoration(
                    labelText: 'GPA Scale',
                    prefixIcon: Icon(Icons.speed),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 4.0,
                      child: Text('4.0 Scale (Standard)'),
                    ),
                    DropdownMenuItem(value: 5.0, child: Text('5.0 Scale')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _gpaScale = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createStudent,
          child: const Text('Create Profile'),
        ),
      ],
    );
  }

  void _createStudent() async {
    if (_formKey.currentState!.validate()) {
      final newStudent = Student(
        id: 'default_student',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        program: _programController.text.trim(),
        programType: _programType,
        programDurationYears: _programDurationYears,
        gpaScale: _gpaScale,
        enrollmentDate: _enrollmentDate,
        startTerm: _startTerm,
        totalCreditsRequired: int.parse(_creditsController.text),
        retakePolicy: _retakePolicy,
      );

      final repository = ref.read(studentRepositoryProvider);
      await repository.saveStudent(newStudent);

      ref.invalidate(currentStudentProvider);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
      }
    }
  }
}
