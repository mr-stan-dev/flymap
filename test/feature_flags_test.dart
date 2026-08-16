import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/app/feature_flags.dart';

void main() {
  test('Sky Camera video is disabled by default', () {
    expect(FeatureFlags.skyCameraVideoCapture, isFalse);
  });
}
