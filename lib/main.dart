import 'dart:io';

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/api_key_store.dart';
import 'services/background_tasks.dart';
import 'services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ApiKeyStore.instance.load();
  await NotificationService.instance.initialize();
  await Workmanager().initialize(callbackDispatcher);
  if (Platform.isAndroid) {
    await Workmanager().registerPeriodicTask(
      'umbrella-weather-refresh',
      kWeatherRefreshTask,
      frequency: const Duration(hours: 3),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
  runApp(const UmbrellaApp());
}
