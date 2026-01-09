import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gpa_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: GPATrackerApp(), // Changed from MyApp to GPATrackerApp
      ),
    );

    // Verify that navigation bar exists
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}