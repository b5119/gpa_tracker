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
}
