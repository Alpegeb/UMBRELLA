// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  final Color bg;
  final Color shellBg;
  final Color shellFrame;
  final Color card;
  final Color cardAlt;
  final Color text;
  final Color sub;
  final Color border;
  final Color accent;   // Umbrella blue
  final Color sunny;    // sunny end of index
  final Color rainy;    // rainy end of index
  final ThemeData materialTheme;

  const AppTheme({
    required this.bg,
    required this.shellBg,
    required this.shellFrame,
    required this.card,
    required this.cardAlt,
    required this.text,
    required this.sub,
    required this.border,
    required this.accent,
    required this.sunny,
    required this.rainy,
    required this.materialTheme,
  });

  static final dark = AppTheme(
    bg: const Color(0xFF0C111C),
    shellBg: const Color(0xFF0C111C),
    shellFrame: const Color(0xFF0A0F19),
    card: const Color(0xFF141B2A),
    cardAlt: const Color(0xFF101723),
    text: const Color(0xFFE8EDF7),
    sub: const Color(0xFFB9C2D3),
    border: const Color(0xFF1C2637),
    accent: const Color(0xFF2D7DF6),
    sunny: const Color(0xFFF6C445),
    rainy: const Color(0xFF2D7DF6),
    materialTheme: ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: Color(0xFF0C111C),
      fontFamily: 'Inter',
    ),
  );

  static final light = AppTheme(
    bg: const Color(0xFFF6F8FC),
    shellBg: const Color(0xFFEFF3FB),
    shellFrame: const Color(0xFFE6EBF7),
    card: const Color(0xFFFFFFFF),
    cardAlt: const Color(0xFFF4F7FD),
    text: const Color(0xFF1C2230),
    sub: const Color(0xFF5B667A),
    border: const Color(0xFFE1E7F2),
    accent: const Color(0xFF2D7DF6),
    sunny: const Color(0xFFF0B12C),
    rainy: const Color(0xFF2D7DF6),
    materialTheme: ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: Color(0xFFF6F8FC),
      fontFamily: 'Inter',
    ),
  );
}