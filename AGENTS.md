AGENTS GUIDE FOR GPA_TRACKER

Project snapshot
- Flutter + Dart 3.9, Riverpod 3, Material 3, sqflite persistence, fl_chart visualization.
- Platforms: mobile (Android/iOS), macOS, web (PWA scaffold in web/).
- Entry point: lib/main.dart -> GPATrackerApp -> MainNavigationScreen with 5 tabs.

Build, lint, test commands
- Install deps: `flutter pub get`
- Analyze (lints): `flutter analyze`
- Format: `dart format .`
- Run all tests: `flutter test`
- Run single test file: `flutter test test/widget_test.dart`
- Run single test by name (plain): `flutter test test/widget_test.dart --plain-name "App smoke test"`
- Flutter doctor (env check): `flutter doctor -v`
- Web debug run: `flutter run -d chrome`
- Android debug run: `flutter run -d emulator-5554` (adjust device id)
- Web build (PWA assets in web/): `flutter build web --release`
- Android build: `flutter build apk --release`
- iOS/macOS build: `flutter build ios --release` / `flutter build macos --release` (requires Xcode setup)

Repository layout
- lib/core/constants/*: app-wide config and static values.
- lib/domain: entities, models, repositories, services, use cases.
- lib/data: SQLite datasources/repositories.
- lib/presentation: screens, dialogs, providers (Riverpod), navigation.
- test/: widget smoke test entry.
- analysis_options.yaml: lint configuration (includes flutter_lints).
- pubspec.yaml: dependencies, assets/fonts stubs.

Coding style (Dart/Flutter)
- Imports: prefer package imports; relative imports within lib/ are ok and used widely; keep `dart:` first, then third-party, then local; avoid duplicate legacy imports unless required (e.g., flutter_riverpod + legacy provider used).
- Null safety: embrace non-nullable by default; mark nullable with `?`; use `!` sparingly—prefer proper checks.
- Immutability: use `const` constructors/widgets where possible; prefer `final` for locals/fields; use `const` lists/maps for constants.
- Naming: classes/types PascalCase; variables, methods, functions lowerCamelCase; files snake_case; constants `static const` with lowerCamelCase in classes; avoid prefixes/suffixes beyond domain meaning.
- Widgets: keep build methods lean; extract UI pieces into widgets when complex; prefer `StatelessWidget` unless stateful is needed; maintain const constructors.
- Layout/theme: Material 3 via `useMaterial3: true`; color scheme seeded with deepPurple; card shapes use 16px radius; honor light/dark themes.
- State management: Riverpod 3 with Provider/StateProvider/NotifierProvider; use `ref.read` for writes and `ref.watch` for rebuild triggers; propagate errors via `AsyncValue.error`.
- Async: return Futures; await repository calls; surface errors rather than swallowing; use try/catch with stackTrace when setting `AsyncValue.error`.
- Error handling: prefer domain-level validation and clear error strings (see TextConstants); avoid bare catches; rethrow when caller must handle (see StudentNotifier.updateStudent).
- Collections: prefer typed lists/maps; avoid dynamic; leverage `equatable` for value equality in domain models.
- Types: explicit types for public APIs and important locals; type inference acceptable for obvious assignments; avoid `var` for top-level constants.
- String formatting: use interpolation; keep user-facing strings in constants classes (TextConstants) for reuse.
- Constants: centralize thresholds/colors in lib/core/constants/app_constants.dart; reuse instead of duplicating literals.
- Date/time: use formats from DateTimeConstants; keep semester names/order consistent with constants.

Riverpod usage patterns
- Providers defined in lib/presentation/providers/app_providers.dart; reuse existing providers rather than creating duplicates.
- Notifier classes load data in build(); keep long work in private methods; set `state = const AsyncValue.loading()` before async work.
- When updating state, catch errors and assign `AsyncValue.error(error, stackTrace)`; rethrow if caller must know.
- Access repositories via providers (databaseServiceProvider -> SQLite repositories).

Navigation and screens
- MainNavigationScreen uses IndexedStack with 5 tabs: Dashboard, Analytics, Career, Predictions, What-If.
- Add new tab: extend `_screens` getter and NavigationDestination list; update indexes consistently.
- Keep screens const where possible; avoid storing BuildContext in state.

Data and persistence
- SQLite via sqflite; database config in DatabaseConstants; default student id `default_student`.
- Repositories: Student/Academic/GPA/GradingConfig each have SQLite implementations; initialize defaults before use (grading config).
- Use UUID package for ids when adding new entities.

Testing guidance
- Widget tests live under test/; keep golden files named with `_golden.png` if added.
- For Riverpod, wrap widgets with `ProviderScope` in tests (see widget_test.dart).
- Use `flutter test --coverage` for coverage if needed.
- Prefer `WidgetTester.pumpWidget` with const widgets; minimize real IO in tests; mock repositories if you add unit tests.

Linting/formatting rules (analysis_options.yaml)
- Uses flutter_lints defaults; honor its warnings.
- Suggested but commented: `prefer_single_quotes`; keep whichever style is present in file; project currently uses double quotes sparingly and single quotes mostly—follow local style.
- Avoid prints; use logging if needed.
- Fix analyzer hints before committing; treat warnings as errors in CI mindset.

UI conventions
- Spacing/radius constants in UIConstants; reuse for paddings, radii, icon sizes.
- Colors: use AppColors for semantic/status colors; prefer getters like `getGPAColor` for GPA-based color logic.
- Text: reuse TextConstants for user-visible strings; align standing labels with academicStandingLabels map.

Domain conventions
- GPA scales and thresholds defined in GPAScales/StatisticalThresholds/CareerConstants; reuse rather than hardcoding.
- Feature toggles in FeatureFlags; check before exposing experimental UI.
- Validation regexes and limits in ValidationConstants; use for forms.

Error + loading UX
- Show loading states with AsyncValue when fetching; set `state = const AsyncValue.loading()` before await calls.
- For failures, surface friendly messages using TextConstants.*; avoid silent catches.

Assets and fonts
- Assets section in pubspec.yaml is commented; uncomment and add files when needed.
- Custom fonts stubbed (Inter); ensure font files exist before enabling.

Performance notes
- Avoid rebuilding heavy widgets by using const and IndexedStack (already used); memoize expensive calculations in providers/services when needed.
- Keep synchronous work light in build(); push heavy logic to use cases/services.

Internationalization
- Currently hardcoded English strings; if adding locales, introduce intl with ARB files and wire via MaterialApp `localizationsDelegates`.

Security and privacy
- Do not log PII; database uses local storage; add encryption layer if handling sensitive data.

CI/CD and tooling
- No CI config present; keep commands reproducible: pub get -> analyze -> format -> test -> build.
- When adding CI, cache Flutter sdk and pub cache; run `flutter doctor -v` once per job to confirm toolchain.

Contributing flow for agents
- Before coding: run `flutter pub get` and `flutter analyze` to catch obvious issues.
- During changes: keep imports ordered; prefer existing constants/providers; maintain null safety.
- After changes: `dart format .` then targeted tests (`flutter test <path> [--plain-name ...]`).
- Document new commands or conventions by updating this file if they materially change workflow.

Cursor/Copilot rules
- No .cursor/rules or .cursorrules files present.
- No .github/copilot-instructions.md present.

Quick references (files)
- Entry widget: lib/main.dart
- Navigation: lib/presentation/screens/main_navigation_screen.dart
- Providers: lib/presentation/providers/app_providers.dart
- Constants: lib/core/constants/app_constants.dart
- Repositories: lib/data/repositories/*.dart
- Use cases: lib/domain/usecases/*.dart
- Widget test: test/widget_test.dart

If you add more tests
- Prefer file-per-widget/use case; mirror lib/ structure under test/.
- Use `setUp`/`tearDown` for DB or stateful objects; consider in-memory DB or mocks for sqflite interactions.

If you add new deps
- Declare in pubspec.yaml; run `flutter pub get`.
- For platform plugins, verify platform folders update; do not commit generated artefacts unless necessary.

Release checklist
- Analyze -> format -> test -> build (target platform).
- Verify version bump in pubspec.yaml if shipping.
- Ensure assets/fonts entries match files to avoid build failures.

End of guide
