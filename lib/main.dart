import 'package:flutter/material.dart';
import 'package:umbrella/router/app_router.dart'; // düzeltildi
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:umbrella/providers/data_provider.dart'; // provider importu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UmbrellaApp());
}

class UmbrellaApp extends StatelessWidget {
  const UmbrellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRouter.generateRoute, // AppRouter burada kullanılacak
        initialRoute: '/',
      ),
    );
  }
}
