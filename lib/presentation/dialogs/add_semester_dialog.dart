import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/semester.dart';
import '../providers/app_providers.dart';

class AddSemesterDialog extends ConsumerStatefulWidget {
  const AddSemesterDialog({super.key});

  @override
  ConsumerState<AddSemesterDialog> createState() => _AddSemesterDialogState();
}

class _AddSemesterDialogState extends ConsumerState<AddSemesterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 120));
  SemesterStatus _status = SemesterStatus.inProgress;
  String _semesterType = 'Fall';
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _updateSemesterName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateSemesterName() {
    _nameController.text = '$_semesterType $_year';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Semester'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Semester Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Quick semester builder
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _semesterType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: DateTimeConstants.semesterNames.map((name) {
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _semesterType = value;
                            _updateSemesterName();
                            _updateDatesForSemesterType(value);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _year,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(10, (index) {
                        final year = DateTime.now().year - 2 + index;
                        return DropdownMenuItem(value: year, child: Text('$year'));
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _year = value;
                            _updateSemesterName();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Custom name override
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Semester Name',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Fall 2024',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter semester name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text(_formatDate(_startDate)),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context, true),
              ),

              // End Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('End Date'),
                subtitle: Text(_formatDate(_endDate)),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context, false),
              ),

              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<SemesterStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SemesterStatus.upcoming,
                    child: Text('Upcoming'),
                  ),
                  DropdownMenuItem(
                    value: SemesterStatus.inProgress,
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: SemesterStatus.completed,
                    child: Text('Completed'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
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
          onPressed: _addSemester,
          child: const Text('Add Semester'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 120));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _updateDatesForSemesterType(String type) {
    final startMonth = DateTimeConstants.semesterStartMonths[type] ?? 1;
    _startDate = DateTime(_year, startMonth, 1);
    _endDate = _startDate.add(const Duration(days: 120));
  }

  void _addSemester() async {
    if (_formKey.currentState!.validate()) {
      if (_endDate.isBefore(_startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date must be after start date')),
        );
        return;
      }

      final studentId = ref.read(currentStudentIdProvider);
      final newSemester = Semester(
        id: const Uuid().v4(),
        studentId: studentId,
        name: _nameController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
        courses: [],
      );

      await ref.read(semestersProvider.notifier).addSemester(newSemester);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newSemester.name} added successfully'),
            action: SnackBarAction(
              label: 'Add Course',
              onPressed: () {
                // TODO: Open add course dialog
              },
            ),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}