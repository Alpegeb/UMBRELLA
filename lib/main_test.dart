import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/api_key_store.dart';
import 'services/notification_service.dart';
import 'main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Keep these lightweight; integration tests run on device/emulator.
  await ApiKeyStore.instance.load();

  try {
    await NotificationService.instance.initialize();
  } catch (_) {
    // Ignore notification init issues in test environment if any.
  }

  runApp(const app.UmbrellaApp());
}
