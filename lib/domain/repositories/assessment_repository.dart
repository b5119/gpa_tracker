import '../entities/assessment.dart';

abstract class AssessmentRepository {
  Future<List<Assessment>> getAssessmentsByCourse(String courseId);
  Future<void> saveAssessment(Assessment assessment);
  Future<void> updateAssessment(Assessment assessment);
  Future<void> deleteAssessment(String assessmentId);
  Future<void> upsertBatch(List<Assessment> assessments);
}
