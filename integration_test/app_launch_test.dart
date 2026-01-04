import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// test entrypoint (no Firebase / Workmanager / notifications)
import 'package:umbrella/main_test.dart' as test_app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches (integration smoke test)', (tester) async {
    // Arrange + Act
    test_app.main();

    // Let the app build and settle
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Assert
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
