import 'package:flutter_test/flutter_test.dart';
import 'package:gpa_tracker/domain/entities/assessment.dart';
import 'package:gpa_tracker/domain/entities/grading_schema.dart';
import 'package:gpa_tracker/domain/usecases/calculate_course_gpa_from_assessments.dart';

void main() {
  final percentageSchema = GradingSchema(
    id: 'percentage_4_scale',
    name: 'Percentage 4.0',
    mode: GradingMode.percentage,
    maxGpa: 4.0,
    percentageBands: {90: 4.0, 80: 3.0, 70: 2.0, 60: 1.0, 0: 0.0},
  );

  final useCase = CalculateCourseGPAFromAssessments();

  test('ignores dropped assessments when calculating course GPA', () {
    final result = useCase.execute(
      assessments: const [
        Assessment(
          id: 'quiz_1',
          courseId: 'course_1',
          name: 'Quiz 1',
          type: AssessmentType.quiz,
          weightPercent: 50,
          totalPoints: 100,
          pointsEarned: 40,
        ),
        Assessment(
          id: 'midterm_1',
          courseId: 'course_1',
          name: 'Midterm',
          type: AssessmentType.midterm,
          weightPercent: 50,
          totalPoints: 100,
          pointsEarned: 100,
          isDropped: true,
        ),
      ],
      gradingSchema: percentageSchema,
    );

    expect(result.weightedPercentage, 40);
    expect(result.gradePoint, 0);
    expect(
      result.warnings,
      contains('Weights do not sum to 100% (current: 50.00).'),
    );
  });

  test('treats all dropped assessments as no graded assessments', () {
    final result = useCase.execute(
      assessments: const [
        Assessment(
          id: 'final_1',
          courseId: 'course_1',
          name: 'Final Exam',
          type: AssessmentType.finalExam,
          weightPercent: 100,
          totalPoints: 100,
          pointsEarned: 95,
          isDropped: true,
        ),
      ],
      gradingSchema: percentageSchema,
    );

    expect(result.weightedPercentage, 0);
    expect(result.gradePoint, 0);
    expect(result.warnings, ['No graded assessments']);
  });
}
