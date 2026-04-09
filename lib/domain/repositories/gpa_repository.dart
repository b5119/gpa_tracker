import '../models/gpa_record.dart';

abstract class GPARepository {
  Future<List<GPARecord>> getGPAHistory(String studentId);
  Future<void> saveGPARecord(GPARecord record);
  Future<GPARecord?> getLatestGPA(String studentId);
}
