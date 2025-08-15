import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/airports_pair.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

extension LatLonListExt on List<ll.LatLng> {
  List<LatLng> toGeometry() {
    return map((point) => point.toMapLatLon()).toList();
  }
}

extension LatLonExt on ll.LatLng {
  LatLng toMapLatLon() => LatLng(latitude, longitude);
}
