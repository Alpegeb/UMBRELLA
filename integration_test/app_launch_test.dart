import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:umbrella/main_test.dart' as test_app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches (integration smoke test)', (tester) async {
    test_app.main(); // <-- await yok

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byKey(const Key('integrationReady')), findsOneWidget);
  });
}
