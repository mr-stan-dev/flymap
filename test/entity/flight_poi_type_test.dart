import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/flight_poi_type.dart';

void main() {
  group('FlightPoiType', () {
    test('maps known raw values', () {
      expect(FlightPoiType.fromRaw('city'), FlightPoiType.city);
      expect(FlightPoiType.fromRaw('river'), FlightPoiType.river);
      expect(FlightPoiType.fromRaw('region'), FlightPoiType.region);
      expect(
        FlightPoiType.fromRaw('mountain_range'),
        FlightPoiType.mountain,
      );
      expect(
        FlightPoiType.fromRaw('mountain range'),
        FlightPoiType.mountain,
      );
      expect(
        FlightPoiType.fromRaw('MOUNTAIN-RANGE'),
        FlightPoiType.mountain,
      );
    });

    test('falls back to unknown for unsupported values', () {
      expect(FlightPoiType.fromRaw('canyon'), FlightPoiType.unknown);
      expect(FlightPoiType.fromRaw(''), FlightPoiType.unknown);
    });
  });
}
