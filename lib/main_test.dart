import 'package:umbrella/main_test.dart' as test_app;
import 'router/app_router.dart';

class UmbrellaAppTest extends StatelessWidget {
  const UmbrellaAppTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UmbrellaAppTest());
}
