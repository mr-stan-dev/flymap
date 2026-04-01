import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/main.dart';

void main() {
  test('MyApp can be instantiated', () {
    const app = MyApp(showOnboarding: false);

    expect(app.showOnboarding, isFalse);
  });
}
