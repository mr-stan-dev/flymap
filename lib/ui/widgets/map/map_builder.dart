import 'package:flymap/entity/airport.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

extension MapLayersExt on MapLibreMapController {
  showRoute(List<ll.LatLng> route) {
    addLine(
      LineOptions(
        lineJoin: 'round',
        geometry: route.toGeometry(),
        lineColor: AppColoursCommon.accentBlue.toHexStringRGB(),
        lineWidth: 2.0,
        lineOpacity: 0.5,
      ),
    );
  }

  showCorridor(List<ll.LatLng> corridor) {
    addLine(
      LineOptions(
        lineJoin: 'round',
        geometry: corridor.toGeometry(),
        lineColor: AppColoursCommon.accentBlue.toHexStringRGB(),
        lineWidth: 3.0,
        lineOpacity: 0.7,
      ),
    );
  }

  showDimmingLayer(List<ll.LatLng> corridor) {
    addFill(
      FillOptions(
        geometry: [
          [
            LatLng(-89.9, -179.9), // Southwest corner
            LatLng(-89.9, 179.9), // Southeast corner
            LatLng(89.9, 179.9), // Northeast corner
            LatLng(89.9, -179.9), // Northwest corner
            LatLng(-89.9, -179.9), // Close the polygon
          ],
          corridor.toGeometry(),
        ],
        fillColor: "#808080",
        fillOpacity: 0.3,
      ),
    );
  }

  /// Add custom airport markers using circles and text symbols
  showAirports(Airport departure, Airport arrival) {
    addSymbol(_airport(departure));
    addSymbol(_airport(arrival));
  }

  SymbolOptions _airport(Airport airport) => SymbolOptions(
    geometry: airport.latLon.toMapLatLon(),
    iconImage: 'airport',
    iconSize: 1.0,
    fontNames: ['Noto Sans Bold'],
    textField: airport.code,
    textSize: 12.0,
    textOffset: const Offset(0, -1.5),
    textColor: Colors.white.toHexStringRGB(),
    textHaloColor: Colors.black.toHexStringRGB(),
    textHaloWidth: 2,
  );
}

extension LatLonListExt on List<ll.LatLng> {
  List<LatLng> toGeometry() {
    return map((point) => point.toMapLatLon()).toList();
  }
}

extension LatLonExt on ll.LatLng {
  LatLng toMapLatLon() => LatLng(latitude, longitude);
}
