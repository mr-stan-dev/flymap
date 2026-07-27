import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/utils/unit_format_utils.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('UnitFormatUtils.formatDistance', () {
    test('groups thousands with the km suffix', () {
      expect(UnitFormatUtils.formatDistance(1000, DistanceUnit.km), '1,000 km');
    });

    test('converts km to miles with the mi suffix', () {
      // 1000 km * 0.621371 = 621.371 -> rounded 621.
      expect(UnitFormatUtils.formatDistance(1000, DistanceUnit.mile), '621 mi');
    });

    test('rounds to whole units', () {
      expect(
        UnitFormatUtils.formatDistance(1487.5, DistanceUnit.km),
        '1,488 km',
      );
      expect(UnitFormatUtils.formatDistance(1487.5, DistanceUnit.mile), '924 mi');
    });

    test('unit labels', () {
      expect(UnitFormatUtils.formatDistanceUnit(DistanceUnit.km), 'km');
      expect(UnitFormatUtils.formatDistanceUnit(DistanceUnit.mile), 'mi');
    });
  });

  group('UnitFormatUtils.formatDistanceApprox', () {
    test('rounds to nearest 10 and groups thousands', () {
      expect(
        UnitFormatUtils.formatDistanceApprox(10447, DistanceUnit.km),
        '10,450 km',
      );
      expect(
        UnitFormatUtils.formatDistanceApprox(347.4, DistanceUnit.km),
        '350 km',
      );
    });
  });

  group('UnitFormatUtils.formatThousands', () {
    test('groups thousands for the app locale', () {
      expect(UnitFormatUtils.formatThousands(10450), '10,450');
      expect(UnitFormatUtils.formatThousands(999), '999');
      expect(UnitFormatUtils.formatThousands(1234567), '1,234,567');
    });
  });
}
