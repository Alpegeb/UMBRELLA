import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/theme_pref.dart';
import '../providers/auth_state.dart';
import '../providers/settings_state.dart';
import '../providers/weather_state.dart';
import '../presentation/screens/auth/auth_gate.dart';

class UmbrellaApp extends StatefulWidget {
  const UmbrellaApp({super.key});

  @override
  State<UmbrellaApp> createState() => _UmbrellaAppState();
}

class _UmbrellaAppState extends State<UmbrellaApp> {
  final _store = ThemePrefStore();
  ThemePref _themePref = ThemePref.system;

  @override
  void initState() {
    super.initState();
    _store.load().then((pref) {
      if (!mounted) return;
      setState(() => _themePref = pref);
    }).catchError((_) {
      // keep system default if storage fails
    });
  }

  AppTheme _paletteFor(BuildContext context) {
    switch (_themePref) {
      case ThemePref.light:
        return AppTheme.light;
      case ThemePref.dark:
        return AppTheme.dark;
      case ThemePref.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        return brightness == Brightness.light ? AppTheme.light : AppTheme.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = _paletteFor(context);

    return MultiProvider(
      providers: [
        Provider<AppTheme>.value(value: appTheme),
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => WeatherState()),

        // ItemsState needs to know the current user for Firestore paths.
      ],
      child: Builder(
        builder: (context) {
          // Recompute in case system theme changes while app is running.
          final themeNow = _themePref == ThemePref.system
              ? (MediaQuery.platformBrightnessOf(context) == Brightness.light
                  ? AppTheme.light
                  : AppTheme.dark)
              : appTheme;

          return MaterialApp(
            title: 'Umbrella',
            debugShowCheckedModeBanner: false,
            theme: themeNow.materialTheme,
            home: AuthGate(
              appTheme: themeNow,
              themePref: _themePref,
              onThemePrefChanged: (pref) {
                setState(() => _themePref = pref);
                _store.save(pref);
              },
            ),
          );
        },
      ),
    );
  }
}
