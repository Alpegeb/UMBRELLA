import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:umbrella/providers/settings_state.dart';

Future<void> _waitLoaded(SettingsState s) async {
  for (int i = 0; i < 100; i++) {
    if (s.loaded) return;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  fail('SettingsState did not load SharedPreferences in time.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SettingsState persists simple preferences (useCelsius, windInKph)', () async {
    // Start with non-default values to verify load.
    SharedPreferences.setMockInitialValues({
      'useCelsius': false,
      'windInKph': false,
      'showUmbrellaIndex': false,
    });

    final s1 = SettingsState();
    await _waitLoaded(s1);

    expect(s1.useCelsius, isFalse);
    expect(s1.windInKph, isFalse);
    expect(s1.showUmbrellaIndex, isFalse);

    // Change values (these do NOT call NotificationService)
    await s1.setUseCelsius(true);
    await s1.setWindInKph(true);
    await s1.setShowUmbrellaIndex(true);

    // New instance should read persisted values
    final s2 = SettingsState();
    await _waitLoaded(s2);

    expect(s2.useCelsius, isTrue);
    expect(s2.windInKph, isTrue);
    expect(s2.showUmbrellaIndex, isTrue);
  });
}
