import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/utils/unit_format_utils.dart';

void main() {
  group('UnitFormatUtils.formatDistance', () {
    test('renders km unchanged with the km suffix', () {
      expect(UnitFormatUtils.formatDistance(1000, DistanceUnit.km), '1000 km');
    });

    test('converts km to miles with the mi suffix', () {
      // 1000 km * 0.621371 = 621.371 -> rounded 621.
      expect(UnitFormatUtils.formatDistance(1000, DistanceUnit.mile), '621 mi');
    });

    test('rounds to whole units', () {
      expect(UnitFormatUtils.formatDistance(1487.5, DistanceUnit.km), '1488 km');
      expect(UnitFormatUtils.formatDistance(1487.5, DistanceUnit.mile), '924 mi');
    });

    test('unit labels', () {
      expect(UnitFormatUtils.formatDistanceUnit(DistanceUnit.km), 'km');
      expect(UnitFormatUtils.formatDistanceUnit(DistanceUnit.mile), 'mi');
    });
  });
}
