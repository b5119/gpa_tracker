import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/grading_config.dart';
import '../providers/app_providers.dart';

class CustomGradingSystemDialog extends ConsumerStatefulWidget {
  final GradingConfig? templateConfig;

  const CustomGradingSystemDialog({super.key, this.templateConfig});

  @override
  ConsumerState<CustomGradingSystemDialog> createState() =>
      _CustomGradingSystemDialogState();
}

class _CustomGradingSystemDialogState
    extends ConsumerState<CustomGradingSystemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxScaleController = TextEditingController();
  final _uuid = const Uuid();
  final List<_GradeRowDraft> _gradeRows = [];

  bool _setActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final template = widget.templateConfig ?? GradingConfig.standardUS4Point0();
    _nameController.text = widget.templateConfig == null
        ? 'My University Scale'
        : '${template.name} Copy';
    _maxScaleController.text = _formatPoint(template.maxGPA);
    for (final entry in template.gradeToPointMap.entries) {
      _gradeRows.add(
        _GradeRowDraft(
          grade: TextEditingController(text: entry.key),
          points: TextEditingController(text: _formatPoint(entry.value)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxScaleController.dispose();
    for (final row in _gradeRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.templateConfig;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: UIConstants.paddingMedium,
        vertical: UIConstants.paddingLarge,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UIConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Grading System',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Text(
                  'Adjust the exact grade points your university uses for GPA calculations.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (template != null) ...[
                  const SizedBox(height: UIConstants.paddingSmall),
                  Text(
                    'Starting from ${template.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: UIConstants.paddingLarge),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'System name',
                    prefixIcon: Icon(Icons.school),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a name for this grading system';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                TextFormField(
                  controller: _maxScaleController,
                  decoration: const InputDecoration(
                    labelText: 'Maximum GPA scale',
                    prefixIcon: Icon(Icons.stacked_line_chart),
                    hintText: '4.0, 4.3, 5.0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid GPA scale';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: UIConstants.paddingLarge),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Grade to point mapping',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addGradeRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add grade'),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                ..._buildGradeRows(),
                const SizedBox(height: UIConstants.paddingMedium),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _setActive,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _setActive = value),
                  title: const Text('Set as active after saving'),
                  subtitle: const Text(
                    'New courses and GPA calculations will use this scale immediately.',
                  ),
                ),
                const SizedBox(height: UIConstants.paddingMedium),
                _PreviewCard(
                  maxScale: double.tryParse(_maxScaleController.text.trim()),
                  gradeCount: _gradeRows.length,
                ),
                const SizedBox(height: UIConstants.paddingLarge),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: UIConstants.paddingSmall),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveConfig,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save System'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGradeRows() {
    return List<Widget>.generate(_gradeRows.length, (index) {
      final row = _gradeRows[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: row.grade,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  hintText: 'A-, B+, Distinction',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: UIConstants.paddingSmall),
            Expanded(
              child: TextFormField(
                controller: row.points,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  hintText: '3.7',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null) {
                    return 'Required';
                  }
                  if (parsed < 0) {
                    return 'Min 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: UIConstants.paddingSmall),
            IconButton(
              onPressed: _isSaving || _gradeRows.length == 1
                  ? null
                  : () => _removeGradeRow(index),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove grade',
            ),
          ],
        ),
      );
    });
  }

  void _addGradeRow() {
    setState(() {
      _gradeRows.add(
        _GradeRowDraft(
          grade: TextEditingController(),
          points: TextEditingController(),
        ),
      );
    });
  }

  void _removeGradeRow(int index) {
    setState(() {
      final row = _gradeRows.removeAt(index);
      row.dispose();
    });
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final maxScale = double.tryParse(_maxScaleController.text.trim());
    if (maxScale == null || maxScale <= 0) {
      _showMessage('Enter a valid GPA scale');
      return;
    }

    final gradeToPointMap = <String, double>{};
    for (final row in _gradeRows) {
      final label = row.grade.text.trim().toUpperCase();
      final point = double.tryParse(row.points.text.trim());

      if (label.isEmpty || point == null) {
        _showMessage('Each grade row needs a label and point value');
        return;
      }
      if (point > maxScale) {
        _showMessage('$label cannot be greater than the max scale');
        return;
      }
      if (gradeToPointMap.containsKey(label)) {
        _showMessage('Duplicate grade label: $label');
        return;
      }

      gradeToPointMap[label] = point;
    }

    final config = (widget.templateConfig ?? GradingConfig.standardUS4Point0())
        .toCustomCopy(
          id: _uuid.v4(),
          name: _nameController.text.trim(),
          maxGPA: maxScale,
          gradeToPointMap: gradeToPointMap,
        );

    setState(() => _isSaving = true);

    try {
      await ref
          .read(gradingConfigProvider.notifier)
          .saveConfig(config, setActive: _setActive);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Failed to save grading system: $error');
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatPoint(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(1)
        : value.toStringAsFixed(2);
  }
}

class _GradeRowDraft {
  final TextEditingController grade;
  final TextEditingController points;

  const _GradeRowDraft({required this.grade, required this.points});

  void dispose() {
    grade.dispose();
    points.dispose();
  }
}

class _PreviewCard extends StatelessWidget {
  final double? maxScale;
  final int gradeCount;

  const _PreviewCard({required this.maxScale, required this.gradeCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UIConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Text(
        maxScale == null
            ? 'Set a GPA scale to preview the configuration.'
            : '$gradeCount grades configured on a ${maxScale!.toStringAsFixed(1)} scale. Academic standing thresholds will be generated automatically.',
      ),
    );
  }
}
