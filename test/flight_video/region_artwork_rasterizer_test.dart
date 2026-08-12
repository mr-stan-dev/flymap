import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/ui/screens/flight_video/rendering/region_artwork_rasterizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rasterizes circular country flags from country_flags assets', () async {
    final rasterizer = RegionArtworkRasterizer();
    final flag = await rasterizer.circularFlag('GB');
    expect(flag, isNotNull);
    expect(flag!.width, RegionArtworkRasterizer.defaultSize.round());

    // Cache returns the same image instance.
    expect(identical(await rasterizer.circularFlag('gb'), flag), isTrue);
    expect(await rasterizer.circularFlag('zz'), isNull);
    expect(await rasterizer.circularFlag(null), isNull);
    rasterizer.dispose();
  });

  test('rasterizes region type artwork from bundled webp icons', () async {
    final rasterizer = RegionArtworkRasterizer();
    final mountains = await rasterizer.typeArtwork(
      RouteRegionType.mountainRange,
    );
    expect(mountains, isNotNull);
    expect(await rasterizer.typeArtwork(RouteRegionType.unknown), isNotNull);
    rasterizer.dispose();
  });
}
