import 'package:flutter_test/flutter_test.dart';
import 'package:gpa_tracker/domain/entities/grading_config.dart';

void main() {
  test('GradingConfig.fromJson parses SQLite-backed rows', () {
    final config = GradingConfig.fromJson({
      'id': 'us_4_0_standard',
      'name': 'US Standard 4.0 Scale',
      'system_type': 'points4_0',
      'max_gpa': 4.0,
      'min_gpa': 0.0,
      'grade_to_point_map': '{"A":4.0,"B":3.0,"F":0.0}',
      'classifications':
          '[{"name":"Dean\'s List","min_gpa":3.5,"color":4283215696},{"name":"At Risk","min_gpa":0.0,"color":4294198070}]',
      'is_default': 1,
      'created_at': '2026-05-16T00:00:00.000',
      'last_modified': null,
    });

    expect(config.id, 'us_4_0_standard');
    expect(config.systemType, GradingSystemType.points4_0);
    expect(config.gradeToPointMap['A'], 4.0);
    expect(config.gradeToPointMap['F'], 0.0);
    expect(config.classifications.first.name, "Dean's List");
    expect(config.isDefault, isTrue);
  });

  test('built-in configs include a simple 4.0 preset', () {
    final configs = GradingConfig.builtInConfigs();

    expect(configs.any((config) => config.id == 'us_4_0_simple'), isTrue);
  });

  test(
    'toCustomCopy creates a custom scale with generated classifications',
    () {
      final config = GradingConfig.standardUS4Point0NoModifiers().toCustomCopy(
        id: 'custom_1',
        name: 'Campus Custom Scale',
        maxGPA: 5.0,
        gradeToPointMap: const {
          'A': 5.0,
          'B': 4.0,
          'C': 3.0,
          'D': 2.0,
          'F': 0.0,
        },
      );

      expect(config.id, 'custom_1');
      expect(config.systemType, GradingSystemType.custom);
      expect(config.maxGPA, 5.0);
      expect(config.gradeToPointMap['A'], 5.0);
      expect(config.classifications.first.minGPA, closeTo(4.375, 0.001));
    },
  );
}
