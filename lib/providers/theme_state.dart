import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePref { light, system, dark }

class ThemeState extends ChangeNotifier {
  static const _k = 'theme_pref';
  ThemePref _pref = ThemePref.system;

  ThemePref get themePref => _pref;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_k);
    _pref = ThemePref.values.firstWhere(
      (e) => e.name == v,
      orElse: () => ThemePref.system,
    );
    notifyListeners();
  }

  Future<void> setPref(ThemePref pref) async {
    _pref = pref;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, pref.name);
  }
}
