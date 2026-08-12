import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/route_region_type.dart';

void main() {
  test('generic artwork covers every region type that lacked an asset', () {
    const genericTypes = <RouteRegionType>[
      RouteRegionType.country,
      RouteRegionType.region,
      RouteRegionType.state,
      RouteRegionType.province,
      RouteRegionType.geoarea,
      RouteRegionType.unknown,
    ];

    for (final type in genericTypes) {
      expect(
        type.assetImagePath,
        'assets/images/regions/generic.webp',
        reason: type.apiValue,
      );
    }
  });

  test('every region type now has bundled artwork', () {
    for (final type in RouteRegionType.values) {
      expect(type.assetImagePath, isNotNull, reason: type.apiValue);
    }
  });
}
