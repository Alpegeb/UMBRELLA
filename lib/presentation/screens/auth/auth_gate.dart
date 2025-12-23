import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../core/theme_pref.dart';
import '../../../providers/auth_state.dart';
import '../../screens/main_screen/main_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.appTheme,
    required this.themePref,
    required this.onThemePrefChanged,
  });

  final AppTheme appTheme;
  final ThemePref themePref;
  final ValueChanged<ThemePref> onThemePrefChanged;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return MainScreen(
            appTheme: appTheme,
            themePref: themePref,
            onThemePrefChanged: onThemePrefChanged,
          );
        }

        return const LoginScreen();
      },
    );
  }
}
