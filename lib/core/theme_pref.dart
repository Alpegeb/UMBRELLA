import 'package:flutter/foundation.dart';

/// Theme selection for the app.
enum ThemePref { light, system, dark }

/// Very small in-memory store (no extra package dependency).
/// If you already have SharedPreferences in the project, tell me—
/// I can give you the persistent version too.
class ThemePrefStore {
  static ThemePref _cached = ThemePref.system;

  Future<ThemePref> load() async {
    // In-memory default (system). Keep it simple for CI/analyze stability.
    return _cached;
  }

  Future<void> save(ThemePref pref) async {
    _cached = pref;
    if (kDebugMode) {
      // ignore: avoid_print
      print("ThemePref saved: $pref");
    }
  }
}
