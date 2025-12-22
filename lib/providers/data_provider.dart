import 'package:flutter/material.dart';

class DataProvider with ChangeNotifier {
  // Örnek veri
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
