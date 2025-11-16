import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'presentation/screens/theme_test/theme_test_screen.dart';
// Or import any screen you're testing.

void main() {
  runApp(const UmbrellaApp());
}

class UmbrellaApp extends StatelessWidget {
  const UmbrellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light; // or AppTheme.dark

    return MaterialApp(
      title: 'Umbrella',
      debugShowCheckedModeBanner: false,
      theme: theme.materialTheme,
      home: const ThemeTestScreen(),
    );
  }
}