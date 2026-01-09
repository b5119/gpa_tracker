// =============================================================================
// APP CONSTANTS
// =============================================================================
// Centralized constants for the GPA Tracker & Career Intelligence application.
// This file contains app-wide configuration, thresholds, and static values.

import 'package:flutter/material.dart';

// =============================================================================
// APP INFORMATION
// =============================================================================

class AppInfo {
  static const String appName = 'GPA Tracker';
  static const String appFullName = 'GPA Tracker & Career Intelligence';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Academic performance analytics with career readiness insights';

  // Contact & Support
  static const String supportEmail = 'support@gpatracker.app';
  static const String websiteUrl = 'https://gpatracker.app';

  // Legal
  static const String privacyPolicyUrl = 'https://gpatracker.app/privacy';
  static const String termsOfServiceUrl = 'https://gpatracker.app/terms';
}

// =============================================================================
// DATABASE CONSTANTS
// =============================================================================

class DatabaseConstants {
  static const String databaseName = 'gpa_tracker.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String studentsTable = 'students';
  static const String semestersTable = 'semesters';
  static const String coursesTable = 'courses';
  static const String gpaRecordsTable = 'gpa_records';

  // Default Values
  static const String defaultStudentId = 'default_student';
}

// =============================================================================
// GPA SCALE CONSTANTS
// =============================================================================

class GPAScales {
  // Standard GPA scales
  static const double scale4Point0 = 4.0;
  static const double scale5Point0 = 5.0;

  // Common GPA thresholds (4.0 scale)
  static const double perfectGPA = 4.0;
  static const double deansListMinimum = 3.5;
  static const double goodStandingMinimum = 3.0;
  static const double satisfactoryMinimum = 2.0;
  static const double probationMinimum = 1.0;

  // Passing grade threshold
  static const double passingGradePoint = 2.0;

  // Grade point mapping for 4.0 scale
  static const Map<String, double> gradePoints4_0 = {
    'A+': 4.0, 'A': 4.0, 'A-': 3.7,
    'B+': 3.3, 'B': 3.0, 'B-': 2.7,
    'C+': 2.3, 'C': 2.0, 'C-': 1.7,
    'D+': 1.3, 'D': 1.0, 'D-': 0.7,
    'F': 0.0,
  };

  // Grade point mapping for 5.0 scale
  static const Map<String, double> gradePoints5_0 = {
    'A+': 5.0, 'A': 5.0, 'A-': 4.7,
    'B+': 4.3, 'B': 4.0, 'B-': 3.7,
    'C+': 3.3, 'C': 3.0, 'C-': 2.7,
    'D+': 2.3, 'D': 2.0, 'D-': 1.7,
    'F': 0.0,
  };

  // Letter grade options
  static const List<String> letterGrades = [
    'A+', 'A', 'A-',
    'B+', 'B', 'B-',
    'C+', 'C', 'C-',
    'D+', 'D', 'D-',
    'F',
  ];
}

// =============================================================================
// ACADEMIC CONSTANTS
// =============================================================================

class AcademicConstants {
  // Credit ranges
  static const int minCreditsPerCourse = 1;
  static const int maxCreditsPerCourse = 6;
  static const int typicalCreditsPerCourse = 3;

  // Semester credit loads
  static const int minCreditsPerSemester = 12; // Full-time minimum
  static const int typicalCreditsPerSemester = 15;
  static const int maxCreditsPerSemester = 18;
  static const int overloadThreshold = 19;

  // Degree requirements
  static const int typicalBachelorsDegreeCredits = 120;
  static const int typicalMastersDegreeCredits = 30;

  // Academic year structure
  static const int semestersPerYear = 2; // Fall and Spring
  static const int weeksPerSemester = 15;

  // Course attempt limits
  static const int maxCourseAttempts = 3;
}

// =============================================================================
// STATISTICAL THRESHOLDS
// =============================================================================

class StatisticalThresholds {
  // Trend analysis
  static const double significantTrendSlope = 0.05; // GPA change per semester
  static const double majorTrendSlope = 0.15;

  // Volatility (standard deviation)
  static const double lowVolatility = 0.15;
  static const double moderateVolatility = 0.30;
  static const double highVolatility = 0.50;

  // Prediction confidence
  static const double highConfidence = 0.8;
  static const double mediumConfidence = 0.5;
  static const double lowConfidence = 0.3;

  // R-squared (goodness of fit)
  static const double excellentFit = 0.9;
  static const double goodFit = 0.7;
  static const double fairFit = 0.5;

  // Semester delta significance
  static const double negligibleDelta = 0.1;
  static const double moderateDelta = 0.3;
  static const double majorDelta = 0.5;

  // Minimum data points for analysis
  static const int minSemestersForTrend = 2;
  static const int minSemestersForPrediction = 3;
  static const int idealSemestersForAnalysis = 4;
}

// =============================================================================
// CAREER INTELLIGENCE CONSTANTS
// =============================================================================

class CareerConstants {
  // Career fit score thresholds
  static const double excellentFitScore = 0.8;
  static const double goodFitScore = 0.6;
  static const double moderateFitScore = 0.4;
  static const double weakFitScore = 0.2;

  // GPA gaps (how close to competitive level)
  static const double easyToReach = 0.2;
  static const double reachable = 0.5;
  static const double challenging = 1.0;

  // Career categories
  static const List<String> careerCategories = [
    'Finance',
    'Consulting',
    'Technology',
    'Healthcare',
    'Academia',
    'Public Sector',
    'Business',
    'Graduate School',
  ];
}

// =============================================================================
// UI CONSTANTS
// =============================================================================

class UIConstants {
  // Padding & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // Chart dimensions
  static const double chartHeightSmall = 150.0;
  static const double chartHeightMedium = 200.0;
  static const double chartHeightLarge = 300.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Card elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}

// =============================================================================
// COLOR CONSTANTS
// =============================================================================

class AppColors {
  // GPA Performance Colors
  static const Color excellentGPA = Color(0xFF4CAF50); // Green
  static const Color goodGPA = Color(0xFF8BC34A); // Light Green
  static const Color satisfactoryGPA = Color(0xFFFFC107); // Amber
  static const Color warningGPA = Color(0xFFFF9800); // Orange
  static const Color criticalGPA = Color(0xFFF44336); // Red

  // Trend Colors
  static const Color improving = Color(0xFF4CAF50);
  static const Color stable = Color(0xFF2196F3);
  static const Color declining = Color(0xFFF44336);

  // Chart Colors
  static const Color primaryChart = Color(0xFF673AB7); // Deep Purple
  static const Color secondaryChart = Color(0xFF9C27B0); // Purple
  static const Color accentChart = Color(0xFF3F51B5); // Indigo

  // Career Readiness Colors
  static const Color highlyCompetitive = Color(0xFF4CAF50);
  static const Color competitive = Color(0xFF8BC34A);
  static const Color eligible = Color(0xFFFFC107);
  static const Color notReady = Color(0xFFFF5722);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Get GPA color based on value
  static Color getGPAColor(double gpa, {double maxScale = 4.0}) {
    final percentage = gpa / maxScale;

    if (percentage >= 0.875) return excellentGPA; // 3.5+ on 4.0 scale
    if (percentage >= 0.75) return goodGPA; // 3.0+ on 4.0 scale
    if (percentage >= 0.50) return satisfactoryGPA; // 2.0+ on 4.0 scale
    if (percentage >= 0.25) return warningGPA; // 1.0+ on 4.0 scale
    return criticalGPA; // Below 1.0
  }
}

// =============================================================================
// TEXT CONSTANTS
// =============================================================================

class TextConstants {
  // Empty States
  static const String noDataAvailable = 'No data available';
  static const String noSemestersYet = 'No semesters added yet';
  static const String noCoursesYet = 'No courses added yet';
  static const String addFirstSemester = 'Add your first semester to get started';

  // Loading States
  static const String loading = 'Loading...';
  static const String calculating = 'Calculating...';
  static const String analyzing = 'Analyzing...';

  // Error Messages
  static const String errorGeneric = 'Something went wrong';
  static const String errorNoGPA = 'Unable to calculate GPA';
  static const String errorInvalidInput = 'Invalid input provided';
  static const String errorDatabaseFailed = 'Database operation failed';

  // Success Messages
  static const String semesterAdded = 'Semester added successfully';
  static const String courseAdded = 'Course added successfully';
  static const String dataUpdated = 'Data updated successfully';
  static const String dataSaved = 'Data saved successfully';

  // Confirmation Messages
  static const String confirmDelete = 'Are you sure you want to delete?';
  static const String confirmDeleteSemester = 'This will delete all courses in this semester';
  static const String cannotUndo = 'This action cannot be undone';

  // Labels
  static const String gpa = 'GPA';
  static const String cumulativeGPA = 'Cumulative GPA';
  static const String semesterGPA = 'Semester GPA';
  static const String credits = 'Credits';
  static const String courses = 'Courses';
  static const String semesters = 'Semesters';

  // Academic Standing
  static const Map<String, String> academicStandingLabels = {
    'deansList': "Dean's List",
    'goodStanding': 'Good Standing',
    'satisfactory': 'Satisfactory',
    'probation': 'Academic Probation',
    'academicDismissal': 'Academic Dismissal',
  };
}

// =============================================================================
// VALIDATION CONSTANTS
// =============================================================================

class ValidationConstants {
  // Field length limits
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;
  static const int maxCourseCodeLength = 20;
  static const int maxCourseNameLength = 200;
  static const int maxDescriptionLength = 1000;

  // Numeric ranges
  static const double minGPA = 0.0;
  static const double maxGPA4_0 = 4.0;
  static const double maxGPA5_0 = 5.0;

  // Regular expressions
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp courseCodeRegex = RegExp(
    r'^[A-Z]{2,4}\s?\d{3,4}[A-Z]?$',
  ); // e.g., CS101, MATH 2110, BIO1001A
}

// =============================================================================
// DATE & TIME CONSTANTS
// =============================================================================

class DateTimeConstants {
  // Date formats
  static const String dateFormatFull = 'MMMM dd, yyyy'; // January 09, 2026
  static const String dateFormatShort = 'MMM dd, yyyy'; // Jan 09, 2026
  static const String dateFormatNumeric = 'MM/dd/yyyy'; // 01/09/2026

  // Semester naming
  static const List<String> semesterNames = [
    'Fall',
    'Spring',
    'Summer',
    'Winter',
  ];

  // Typical semester start months
  static const Map<String, int> semesterStartMonths = {
    'Fall': 8, // August
    'Spring': 1, // January
    'Summer': 5, // May
    'Winter': 12, // December
  };
}

// =============================================================================
// FEATURE FLAGS
// =============================================================================

class FeatureFlags {
  // Feature toggles for gradual rollout
  static const bool enableCareerIntelligence = true;
  static const bool enablePredictions = true;
  static const bool enableWhatIfSimulator = true;
  static const bool enableCloudSync = false; // Future feature
  static const bool enableSocialFeatures = false; // Future feature
  static const bool enableExport = true;
  static const bool enableDarkMode = true;

  // Experimental features (hidden from UI)
  static const bool enableAdvancedAnalytics = false;
  static const bool enableAIRecommendations = false;
}

// =============================================================================
// STORAGE KEYS
// =============================================================================

class StorageKeys {
  // SharedPreferences keys
  static const String currentStudentId = 'current_student_id';
  static const String selectedThemeMode = 'selected_theme_mode';
  static const String hasCompletedOnboarding = 'has_completed_onboarding';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String userPreferences = 'user_preferences';
}