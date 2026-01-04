import 'package:flutter/material.dart';

class UmbrellaIntegrationTestApp extends StatelessWidget {
  const UmbrellaIntegrationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('integration-ready', key: Key('integrationReady')),
        ),
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UmbrellaIntegrationTestApp());
}
