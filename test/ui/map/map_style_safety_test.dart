import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/ui/map/map_style_safety.dart';

void main() {
  test('detects stale style platform exception', () {
    final error = PlatformException(
      code: 'error',
      message: 'Calling addLayer when a newer style is loading/has loaded.',
    );

    expect(isStaleStylePlatformException(error), isTrue);
  });

  test('ignores unrelated platform exception', () {
    final error = PlatformException(
      code: 'error',
      message: 'Something else failed.',
    );

    expect(isStaleStylePlatformException(error), isFalse);
  });
}
