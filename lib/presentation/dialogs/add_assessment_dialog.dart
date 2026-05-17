import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/assessment.dart';
import '../providers/app_providers.dart';

class AddAssessmentDialog extends ConsumerStatefulWidget {
  final String courseId;
  final Assessment? initial;

  const AddAssessmentDialog({super.key, required this.courseId, this.initial});

  @override
  ConsumerState<AddAssessmentDialog> createState() =>
      _AddAssessmentDialogState();
}

class _AddAssessmentDialogState extends ConsumerState<AddAssessmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalPointsController = TextEditingController();
  final _earnedPointsController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  AssessmentType _type = AssessmentType.assignment;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _type = initial.type;
      _totalPointsController.text = initial.totalPoints.toStringAsFixed(1);
      if (initial.pointsEarned != null) {
        _earnedPointsController.text = initial.pointsEarned!.toStringAsFixed(1);
      }
      _weightController.text = initial.weightPercent.toStringAsFixed(1);
      _dueDate = initial.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalPointsController.dispose();
    _earnedPointsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assessmentsAsync = ref.watch(assessmentsProvider(widget.courseId));

    final double currentWeight = assessmentsAsync.when(
      data: (items) =>
          items.fold<double>(0.0, (sum, a) => sum + a.weightPercent),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final title = widget.initial == null ? 'Add Assessment' : 'Edit Assessment';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Assessment Name *',
                  prefixIcon: Icon(Icons.assignment),
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length > 100) {
                    return 'Max 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: UIConstants.paddingMedium),

              DropdownButtonFormField<AssessmentType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: AssessmentType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_labelForType(t)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
              const SizedBox(height: UIConstants.paddingMedium),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalPointsController,
                      decoration: const InputDecoration(
                        labelText: 'Total Points *',
                        prefixIcon: Icon(Icons.calculate),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: UIConstants.paddingMedium),
                  Expanded(
                    child: TextFormField(
                      controller: _earnedPointsController,
                      decoration: const InputDecoration(
                        labelText: 'Points Earned',
                        prefixIcon: Icon(Icons.check_circle_outline),
                        border: OutlineInputBorder(),
                        hintText: 'Leave empty if not graded',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed < 0) {
                          return 'Must be >= 0';
                        }
                        final total = double.tryParse(
                          _totalPointsController.text,
                        );
                        if (total != null && parsed > total) {
                          return 'Cannot exceed total points';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.paddingMedium),

              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (%) *',
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null) return 'Required';
                  if (parsed < 0 || parsed > 100) return '0 - 100 only';
                  if (_wouldExceedWeight(parsed, currentWeight)) {
                    return 'Total weight exceeds 100%';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _weightSummary(currentWeight),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (_warningText(currentWeight) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _warningText(currentWeight)!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: UIConstants.paddingMedium),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Due date'),
                subtitle: Text(
                  _dueDate == null
                      ? 'Optional'
                      : DateFormat.yMMMd().format(_dueDate!),
                ),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Select'),
                ),
              ),

              const SizedBox(height: UIConstants.paddingMedium),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
        ElevatedButton.icon(
          onPressed: () => _save(context),
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  bool _wouldExceedWeight(double newWeight, double currentWeight) {
    final existing = widget.initial?.weightPercent ?? 0.0;
    final totalAfter = currentWeight - existing + newWeight;
    return totalAfter > 100.0 + 1e-3;
  }

  String _weightSummary(double currentWeight) {
    final existing = widget.initial?.weightPercent ?? 0.0;
    final adjustedCurrent = currentWeight - existing;
    final entered = double.tryParse(_weightController.text) ?? 0;
    final total = adjustedCurrent + entered;
    final remaining = (100 - total).clamp(0.0, 100.0).toDouble();
    return 'Current total: ${total.toStringAsFixed(1)}% (${remaining.toStringAsFixed(1)}% remaining)';
  }

  String? _warningText(double currentWeight) {
    final entered = double.tryParse(_weightController.text);
    if (entered == null) return null;
    if (_wouldExceedWeight(entered, currentWeight)) {
      return 'Warning: total weight would exceed 100%';
    }
    return null;
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final totalPoints = double.parse(_totalPointsController.text);
    final pointsEarned = _earnedPointsController.text.isEmpty
        ? null
        : double.parse(_earnedPointsController.text);
    final weight = double.parse(_weightController.text);

    final assessment = Assessment(
      id: widget.initial?.id ?? _generateId(),
      courseId: widget.courseId,
      name: _nameController.text.trim(),
      type: _type,
      weightPercent: weight,
      totalPoints: totalPoints,
      pointsEarned: pointsEarned,
      dueDate: _dueDate,
    );

    final notifier = ref.read(assessmentsProvider(widget.courseId).notifier);
    if (widget.initial == null) {
      await notifier.addAssessment(assessment);
      _showSnack('Assessment added');
    } else {
      await notifier.updateAssessment(assessment);
      _showSnack('Assessment updated');
    }

    if (context.mounted) Navigator.pop(context, assessment);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _labelForType(AssessmentType type) {
    switch (type) {
      case AssessmentType.assignment:
        return 'Assignment';
      case AssessmentType.quiz:
        return 'Quiz';
      case AssessmentType.midterm:
        return 'Midterm';
      case AssessmentType.finalExam:
        return 'Final Exam';
      case AssessmentType.project:
        return 'Project';
    }
  }

  String _generateId() => 'assessment_${DateTime.now().millisecondsSinceEpoch}';
}
