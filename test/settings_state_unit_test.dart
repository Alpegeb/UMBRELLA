import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:umbrella/providers/settings_state.dart';

Future<void> _waitLoaded(SettingsState s) async {
  for (int i = 0; i < 200; i++) {
    if (s.loaded) return;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  fail('SettingsState did not load SharedPreferences in time.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SettingsState persists preferences across instances', () async {
    // Arrange
    SharedPreferences.setMockInitialValues({});
    final s1 = SettingsState();
    await _waitLoaded(s1);

    final oldUseC = s1.useCelsius;
    final oldWind = s1.windInKph;
    final oldUmb = s1.showUmbrellaIndex;

    // Act
    await s1.setUseCelsius(!oldUseC);
    await s1.setWindInKph(!oldWind);
    await s1.setShowUmbrellaIndex(!oldUmb);

    final s2 = SettingsState();
    await _waitLoaded(s2);

    // Assert
    expect(s2.useCelsius, equals(!oldUseC));
    expect(s2.windInKph, equals(!oldWind));
    expect(s2.showUmbrellaIndex, equals(!oldUmb));
  });
}
