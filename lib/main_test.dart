import 'package:flutter/material.dart';
import 'router/app_router.dart';

class UmbrellaAppTest extends StatelessWidget {
  const UmbrellaAppTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UmbrellaAppTest());
}
