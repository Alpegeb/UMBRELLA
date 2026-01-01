import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:umbrella/providers/settings_state.dart';

class _SettingsHarness extends StatelessWidget {
  const _SettingsHarness({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => SettingsState(),
        child: const _SettingsView(),
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, s, _) {
        if (!s.loaded) {
          return const Scaffold(
            body: Center(child: Text('loading')),
          );
        }

        return Scaffold(
          body: Center(
            child: Text(
              'umbrella:${s.showUmbrellaIndex} celsius:${s.useCelsius}',
              key: const Key('stateText'),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            key: const Key('toggleCelsius'),
            onPressed: () async {
              await context.read<SettingsState>().setUseCelsius(!s.useCelsius);
            },
            child: const Icon(Icons.swap_horiz),
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

  testWidgets('SettingsState loads defaults and toggles useCelsius in UI', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // ✅ key verildi -> unused_element_parameter warning biter
    await tester.pumpWidget(const _SettingsHarness(key: Key('settingsHarness')));
    expect(find.text('loading'), findsOneWidget);

    await _pumpUntilLoaded(tester);

    expect(find.byKey(const Key('stateText')), findsOneWidget);
    expect(find.text('umbrella:true celsius:true'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggleCelsius')));
    await tester.pumpAndSettle();

    expect(find.text('umbrella:true celsius:false'), findsOneWidget);
  });
}
