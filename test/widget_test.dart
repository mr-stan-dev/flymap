import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/app/flymap_app.dart';

void main() {
  test('FlymapApp can be instantiated', () {
    const app = FlymapApp(showOnboarding: false);

    expect(app.showOnboarding, isFalse);
  });
}
