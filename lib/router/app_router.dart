import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/auth_state.dart';
import '../providers/items_state.dart';
import '../providers/settings_state.dart';
import '../providers/weather_state.dart';
import '../presentation/screens/auth/auth_gate.dart';

enum ThemePref { light, system, dark }

class UmbrellaApp extends StatefulWidget {
  const UmbrellaApp({super.key});

  @override
  State<UmbrellaApp> createState() => _UmbrellaAppState();
}

class _UmbrellaAppState extends State<UmbrellaApp> {
  ThemePref _themePref = ThemePref.system;

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

        ChangeNotifierProxyProvider<AuthState, ItemsState>(
          create: (_) => ItemsState(),
          update: (_, auth, items) {
            final st = items ?? ItemsState(); // <-- null-safe
            st.bindUser(auth.user);
            return st;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Umbrella',
        debugShowCheckedModeBanner: false,
        theme: appTheme.materialTheme,
        home: AuthGate(
          appTheme: appTheme,
          themePref: _themePref,
          onThemePrefChanged: (pref) => setState(() => _themePref = pref),
        ),
      ),
    );
  }
}
