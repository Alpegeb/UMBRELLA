import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:umbrella/providers/settings_state.dart';

class _UmbrellaToggleHarness extends StatelessWidget {
  const _UmbrellaToggleHarness();

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
  const _UmbrellaToggleView();

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
            // ✅ garanti ikon (her sürümde var)
            child: const Icon(Icons.beach_access),
          ),
        );
      },
    );
  }
}

Future<void> _pumpUntilLoaded(WidgetTester tester) async {
  for (int i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (find.text('loading').evaluate().isEmpty) return;
  }
  fail('SettingsState did not finish loading (SharedPreferences) in time.');
}

String _umbrellaText(WidgetTester tester) {
  final t = tester.widget<Text>(find.byKey(const Key('umbrellaText')));
  return (t.data ?? '').trim();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tapping FAB toggles showUmbrellaIndex text', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const _UmbrellaToggleHarness());
    expect(find.text('loading'), findsOneWidget);

    await _pumpUntilLoaded(tester);

    final before = _umbrellaText(tester);

    await tester.tap(find.byKey(const Key('toggleUmbrella')));
    await tester.pumpAndSettle();
    final after1 = _umbrellaText(tester);
    expect(after1, isNot(equals(before)));

    await tester.tap(find.byKey(const Key('toggleUmbrella')));
    await tester.pumpAndSettle();
    final after2 = _umbrellaText(tester);
    expect(after2, equals(before));
  });
}
