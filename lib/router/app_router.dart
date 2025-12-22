import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/auth_state.dart';
import '../providers/items_state.dart';
import '../providers/theme_state.dart';
import '../presentation/screens/auth/auth_gate.dart';

class UmbrellaApp extends StatelessWidget {
  const UmbrellaApp({super.key});

  AppTheme _paletteFor(BuildContext context, ThemePref pref) {
    switch (pref) {
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),

        ChangeNotifierProxyProvider<AuthState, ItemsState>(
          create: (_) => ItemsState(),
          update: (_, auth, items) {
            final st = items ?? ItemsState();
            st.bindUser(auth.user);
            return st;
          },
        ),

        ChangeNotifierProvider(
          create: (_) => ThemeState()..load(),
        ),
      ],
      child: Consumer<ThemeState>(
        builder: (context, themeState, _) {
          final pref = themeState.pref;
          final appTheme = _paletteFor(context, pref);

          return MaterialApp(
            title: 'Umbrella',
            debugShowCheckedModeBanner: false,
            theme: appTheme.materialTheme,
            home: AuthGate(
              appTheme: appTheme,
              themePref: pref,
              onThemePrefChanged: (p) =>
                  context.read<ThemeState>().setPref(p),
            ),
          );
        },
      ),
    );
  }
}
