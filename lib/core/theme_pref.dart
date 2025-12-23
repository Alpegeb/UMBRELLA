import 'package:shared_preferences/shared_preferences.dart';

enum ThemePref { light, system, dark }

class ThemePrefStore {
  static const _k = 'theme_pref';

  Future<ThemePref> load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_k) ?? ThemePref.system.name;

    return ThemePref.values.firstWhere(
      (e) => e.name == v,
      orElse: () => ThemePref.system,
    );
  }

  Future<void> save(ThemePref pref) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, pref.name);
  }
}
