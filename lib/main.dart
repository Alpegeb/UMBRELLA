import 'package:flutter/material.dart';
import 'package:umbrella/providers/data_provider.dart';
import 'package:umbrella/app_router.dart';
import 'package:provider/provider.dart';

void main() {
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
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: '/',
      ),
    );
  }
}
