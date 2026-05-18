# GPA Tracker & Career Intelligence

A comprehensive **Flutter + Dart** mobile application for tracking academic GPA across semesters with advanced statistical analysis, predictive modeling, and career readiness intelligence mapped to employment sector requirements.

## Features

- **📊 GPA Tracking**: Track grades, calculate GPA by semester, and maintain a complete academic history
- **📈 Statistical Analysis**: Analyze trends, visualize performance metrics with interactive charts
- **🔮 Predictive Modeling**: Forecast GPA outcomes based on historical performance
- **💼 Career Mapping**: Align academic performance with real-world employment sector requirements
- **🎯 What-If Analysis**: Simulate future scenarios and explore different academic paths
- **📱 Cross-Platform**: Runs on Android, iOS, macOS, and Web (PWA)
- **💾 Local Persistence**: SQLite-backed offline-first architecture

## Tech Stack

- **Framework**: Flutter 3.9 with Material Design 3
- **Language**: Dart 3.9
- **State Management**: Riverpod 3
- **Database**: SQLite with sqflite
- **Data Visualization**: fl_chart
- **Code Quality**: flutter_lints

## Getting Started

### Prerequisites

- Flutter SDK ≥3.9.0
- Dart ≥3.9.0
- An emulator or physical device

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd gpa_tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Build Commands

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install dependencies |
| `flutter analyze` | Lint check |
| `dart format .` | Format code |
| `flutter test` | Run all tests |
| `flutter run -d chrome` | Web debug |
| `flutter run -d emulator-5554` | Android debug |
| `flutter build web --release` | Web production (PWA) |
| `flutter build apk --release` | Android production |
| `flutter build ios --release` | iOS production |

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App-wide configuration & constants
│   └── theme/              # Material 3 theme configuration
├── domain/
│   ├── entities/           # Domain models with business logic
│   ├── repositories/       # Abstract repository interfaces
│   ├── services/           # Business logic services
│   └── usecases/           # Feature-specific use cases
├── data/
│   ├── repositories/       # SQLite repository implementations
│   └── datasources/        # Database layer
├── presentation/
│   ├── screens/            # UI screens for each tab
│   ├── dialogs/            # Modal dialogs & popups
│   ├── widgets/            # Reusable UI components
│   └── providers/          # Riverpod state management
├── main.dart               # App entry point
└── test/
    └── widget_test.dart    # Widget smoke tests

```

## Navigation

The app uses a **5-tab navigation** system:

1. **Dashboard** - Overview of current semester GPA and quick stats
2. **Analytics** - Historical performance trends and visualizations
3. **Career** - Career sector mapping and requirements alignment
4. **Predictions** - Predictive GPA modeling and forecasting
5. **What-If** - Scenario planning and academic path exploration

## Data Models

### Key Entities

- **Student**: Academic profile with name and contact info
- **AcademicRecord**: Semester-level courses and grades
- **GPA**: Calculated GPA metrics and academic standing
- **GradingConfig**: Grading scale and GPA calculation rules
- **Career Profile**: Employment sector requirements and alignment

## Architecture Patterns

- **State Management**: Riverpod providers with notifiers for async state
- **Error Handling**: AsyncValue-based error propagation with user-friendly messages
- **Validation**: Domain-level validation with centralized error constants
- **Persistence**: Repository pattern abstracting SQLite implementation

## Development Guidelines

### Code Style

- Use **null safety** - prefer non-nullable by default
- Prefer **const constructors** for widgets
- Use **final** for local variables and fields
- Follow **PascalCase** for types, **lowerCamelCase** for variables/functions
- Place user-facing strings in `TextConstants` for reuse

### Riverpod Usage

- Define providers in `lib/presentation/providers/app_providers.dart`
- Use `ref.watch` for UI rebuilds and `ref.read` for write operations
- Load data in notifier `build()` methods
- Surface errors with `AsyncValue.error` instead of swallowing them

### Testing

Run widget tests:
```bash
flutter test
flutter test test/widget_test.dart --plain-name "App smoke test"
```

## Configuration

Key configuration files:

- `analysis_options.yaml` - Lint rules (flutter_lints)
- `pubspec.yaml` - Dependencies and asset declarations
- `lib/core/constants/app_constants.dart` - App-wide thresholds and styling

## Contributing

1. Run `flutter pub get` before starting
2. Use `flutter analyze` to check for issues
3. Format code with `dart format .`
4. Write tests for new features
5. Keep commits atomic and well-described

## License

This project is provided as-is for educational and personal use.

## Support

For issues, questions, or feature requests, please open an issue in the repository.

---

**Version**: 1.0.0 | **Built with Flutter & Dart** | **Material Design 3**
