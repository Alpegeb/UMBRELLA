import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:umbrella/main_test.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches successfully', (tester) async {
    await app.main();

    // Let first frames + async inits settle
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Simple assertion: app builds a MaterialApp somewhere
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
