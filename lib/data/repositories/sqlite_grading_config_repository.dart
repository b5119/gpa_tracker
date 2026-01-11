import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/grading_config.dart';
import '../../domain/repositories/grading_config_repository.dart';
import '../datasources/local/database_service.dart';

class SQLiteGradingConfigRepository implements GradingConfigRepository {
  final DatabaseService _dbService;

  SQLiteGradingConfigRepository(this._dbService);

  @override
  Future<GradingConfig?> getActiveConfig() async {
    final db = await _dbService.database;

    final results = await db.query(
      'grading_configs',
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (results.isEmpty) {
      // Initialize defaults if none exist
      await initializeDefaults();
      return await getActiveConfig();
    }

    return GradingConfig.fromJson(results.first);
  }

  @override
  Future<List<GradingConfig>> getAllConfigs() async {
    final db = await _dbService.database;
    final results = await db.query('grading_configs', orderBy: 'name ASC');

    return results.map((json) => GradingConfig.fromJson(json)).toList();
  }

  @override
  Future<GradingConfig?> getConfigById(String id) async {
    final db = await _dbService.database;

    final results = await db.query(
      'grading_configs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return GradingConfig.fromJson(results.first);
  }

  @override
  Future<void> saveConfig(GradingConfig config) async {
    final db = await _dbService.database;

    await db.insert(
      'grading_configs',
      _toDatabase(config),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateConfig(GradingConfig config) async {
    final db = await _dbService.database;

    await db.update(
      'grading_configs',
      _toDatabase(config),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  @override
  Future<void> deleteConfig(String id) async {
    final db = await _dbService.database;

    await db.delete(
      'grading_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> setActiveConfig(String id) async {
    final db = await _dbService.database;

    // Deactivate all configs
    await db.update(
      'grading_configs',
      {'is_default': 0},
    );

    // Activate selected config
    await db.update(
      'grading_configs',
      {'is_default': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> initializeDefaults() async {
    final configs = await getAllConfigs();

    if (configs.isEmpty) {
      // Add default US 4.0 system
      await saveConfig(GradingConfig.standardUS4Point0());
      await saveConfig(GradingConfig.standardUS5Point0());
      await saveConfig(GradingConfig.ukPercentage());
    }
  }

  /// Convert GradingConfig to database format
  Map<String, dynamic> _toDatabase(GradingConfig config) {
    final json = config.toJson();

    return {
      'id': json['id'],
      'name': json['name'],
      'system_type': json['system_type'],
      'max_gpa': json['max_gpa'],
      'min_gpa': json['min_gpa'],
      'grade_to_point_map': jsonEncode(json['grade_to_point_map']),
      'classifications': jsonEncode(json['classifications']),
      'is_default': json['is_default'] ? 1 : 0,
      'created_at': json['created_at'],
      'last_modified': json['last_modified'],
    };
  }
}