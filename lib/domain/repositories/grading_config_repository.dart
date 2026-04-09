import '../entities/grading_config.dart';

/// Repository interface for grading configuration persistence
///
/// WHY THIS EXISTS:
/// Grading configurations are first-class domain entities that must be:
/// - Persisted locally (SQLite)
/// - Retrievable by ID
/// - Updateable when policies change
/// - Switchable (multiple configs for comparison)
abstract class GradingConfigRepository {
  /// Get the active grading configuration
  Future<GradingConfig?> getActiveConfig();

  /// Get all saved grading configurations
  Future<List<GradingConfig>> getAllConfigs();

  /// Get specific grading configuration by ID
  Future<GradingConfig?> getConfigById(String id);

  /// Save new grading configuration
  Future<void> saveConfig(GradingConfig config);

  /// Update existing grading configuration
  Future<void> updateConfig(GradingConfig config);

  /// Delete grading configuration
  Future<void> deleteConfig(String id);

  /// Set a configuration as active/default
  Future<void> setActiveConfig(String id);

  /// Initialize with default configurations if none exist
  Future<void> initializeDefaults();
}
