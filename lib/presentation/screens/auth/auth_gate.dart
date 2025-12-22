import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/screens/main_screen/main_screen.dart';
import '../../../core/app_theme.dart';
import '../../../providers/auth_provider.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.appTheme,
    required this.themePref,
    required this.onThemePrefChanged,
  });

  final AppTheme appTheme;
  final dynamic themePref;
  final ValueChanged<dynamic> onThemePrefChanged;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
