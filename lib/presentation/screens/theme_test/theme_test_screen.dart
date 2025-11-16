import 'package:flutter/material.dart';
import '../../../../../core/app_theme.dart';

class ThemeTestScreen extends StatefulWidget {
  const ThemeTestScreen({super.key});

  @override
  State<ThemeTestScreen> createState() => _ThemeTestScreenState();
}

class _ThemeTestScreenState extends State<ThemeTestScreen> {
  bool isLight = true;

  @override
  Widget build(BuildContext context) {
    final theme = isLight ? AppTheme.light : AppTheme.dark;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: Text(
          isLight ? "Light Theme" : "Dark Theme",
          style: TextStyle(color: theme.text),
        ),
        backgroundColor: theme.card,
        iconTheme: IconThemeData(color: theme.text),
        actions: [
          IconButton(
            icon: Icon(
              isLight ? Icons.dark_mode : Icons.light_mode,
              color: theme.sub,
            ),
            onPressed: () => setState(() => isLight = !isLight),
          ),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Umbrella Blue",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Main Text Color Example",
                style: TextStyle(color: theme.text),
              ),
              const SizedBox(height: 8),
              Text(
                "Subtext Color Example",
                style: TextStyle(color: theme.sub),
              ),
              const SizedBox(height: 16),
              Container(
                height: 40,
                width: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.rainy,
                      Color.lerp(theme.rainy, theme.sunny, 0.5)!,
                      theme.sunny,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}