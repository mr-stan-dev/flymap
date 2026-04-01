import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/land_mask_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LandMaskProvider coastline mask', () {
    test('classifies open ocean as sea and inland city as land', () async {
      final provider = LandMaskProvider();
      await provider.ensureInitialized();

      expect(provider.pointIsOverLand(0.0, -30.0), isFalse);
      expect(provider.pointIsOverLand(48.8566, 2.3522), isTrue); // Paris
    });

    test('classifies mid English Channel as sea', () async {
      final provider = LandMaskProvider();
      await provider.ensureInitialized();

      // Between UK and France
      expect(provider.pointIsOverLand(50.95, 1.85), isFalse);
    });
  });
}
