import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../presentation/screens/main_screen/main_screen.dart';

// ✅ Step 3 (Firestore data layer)
import '../core/data/repositories/reminder_repository.dart';
import '../presentation/screens/reminders/reminders_screen.dart';

enum ThemePref { light, system, dark }

class UmbrellaApp extends StatefulWidget {
  const UmbrellaApp({super.key});

  @override
  State<UmbrellaApp> createState() => _UmbrellaAppState();
}

class _UmbrellaAppState extends State<UmbrellaApp> {
  ThemePref _themePref = ThemePref.system;

  // ✅ Provider yoksa: repo burada tek instance olsun
  final ReminderRepository _reminderRepo = ReminderRepository();

  // ✅ Şimdilik demo uid (auth yoksa)
  // Auth gelince burayı FirebaseAuth.instance.currentUser!.uid yaparsınız.
  static const String _demoUid = 'demo-user';

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

    return MaterialApp(
      title: 'Umbrella',
      debugShowCheckedModeBanner: false,
      theme: appTheme.materialTheme,

      // ✅ Routing (provider yoksa bu yeter)
      routes: {
        '/': (_) => MainScreen(
              appTheme: appTheme,
              themePref: _themePref,
              onThemePrefChanged: (pref) => setState(() => _themePref = pref),
            ),
        '/reminders': (_) => RemindersScreen(
              uid: _demoUid,
              repo: _reminderRepo,
            ),
      },

      initialRoute: '/',
    );
  }
}
