import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main_test.dart' as test_app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches (integration smoke test)', (tester) async {
    test_app.main();

    // Let initial async work settle (routing, providers, etc.)
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // If the app launches, we should have a MaterialApp somewhere in the tree.
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
