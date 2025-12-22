import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePref { light, system, dark }

class ThemeState extends ChangeNotifier {
  static const _kThemePref = 'theme_pref';

  ThemePref _pref = ThemePref.system;
  bool _loaded = false;

  ThemePref get pref => _pref;
  bool get loaded => _loaded;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kThemePref);

    _pref = ThemePref.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ThemePref.system,
    );

    _loaded = true;
    notifyListeners();
  }

  Future<void> setPref(ThemePref p) async {
    _pref = p;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kThemePref, p.name);
  }
}
