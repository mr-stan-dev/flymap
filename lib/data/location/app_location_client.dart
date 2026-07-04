import 'package:geolocator/geolocator.dart';

abstract class AppLocationClient {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Future<Position> getCurrentPosition({required LocationAccuracy accuracy});

  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  });
}
