import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:umbrella/providers/settings_state.dart';

class _UmbrellaToggleHarness extends StatelessWidget {
  const _UmbrellaToggleHarness({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => SettingsState(),
        child: const _UmbrellaToggleView(),
      ),
    );
  }
}

class _UmbrellaToggleView extends StatelessWidget {
  const _UmbrellaToggleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, s, _) {
        if (!s.loaded) {
          return const Scaffold(body: Center(child: Text('loading')));
        }

        return Scaffold(
          body: Center(
            child: Text(
              'umbrella:${s.showUmbrellaIndex}',
              key: const Key('umbrellaText'),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            key: const Key('toggleUmbrella'),
            onPressed: () async {
              await context
                  .read<SettingsState>()
                  .setShowUmbrellaIndex(!s.showUmbrellaIndex);
            },
            child: const Icon(Icons.umbrella),
          ),
        );
      },
    );
  }
}

Future<void> _pumpUntilLoaded(WidgetTester tester) async {
  for (int i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (find.text('loading').evaluate().isEmpty) return;
  }
  fail('SettingsState did not finish loading (SharedPreferences) in time.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsState toggles showUmbrellaIndex in UI', (tester) async {
    // Start with default values
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const _UmbrellaToggleHarness());
    expect(find.text('loading'), findsOneWidget);

    await _pumpUntilLoaded(tester);

    // Default: true
    expect(find.byKey(const Key('umbrellaText')), findsOneWidget);
    expect(find.text('umbrella:true'), findsOneWidget);

    // Toggle -> false
    await tester.tap(find.byKey(const Key('toggleUmbrella')));
    await tester.pumpAndSettle();
    expect(find.text('umbrella:false'), findsOneWidget);

    // Toggle -> true
    await tester.tap(find.byKey(const Key('toggleUmbrella')));
    await tester.pumpAndSettle();
    expect(find.text('umbrella:true'), findsOneWidget);
  });
}
