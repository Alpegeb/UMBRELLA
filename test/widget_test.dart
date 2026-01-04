import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('smoke test', () {
    expect(1, equals(1));
  });
}
