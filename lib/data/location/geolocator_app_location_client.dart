import 'package:flymap/data/location/app_location_client.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorAppLocationClient implements AppLocationClient {
  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<Position> getCurrentPosition({required LocationAccuracy accuracy}) {
    return Geolocator.getCurrentPosition(desiredAccuracy: accuracy);
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }
}
