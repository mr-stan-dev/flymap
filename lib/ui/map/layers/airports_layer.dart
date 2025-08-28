import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/map_layer.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class AirportsLayer extends MapLayer {
  late SymbolOptions departureOptions;
  late SymbolOptions arrivalOptions;

  AirportsLayer({required Airport departure, required Airport arrival}) {
    departureOptions = _airport(departure);
    arrivalOptions = _airport(arrival);
  }

  @override
  void add(MapLibreMapController controller) {
    controller.addSymbol(departureOptions);
    controller.addSymbol(arrivalOptions);
  }

  SymbolOptions _airport(Airport airport) => SymbolOptions(
    geometry: airport.latLon.toMapLatLon(),
    iconImage: 'airport',
    iconSize: 1.0,
    fontNames: ['Noto Sans Bold'],
    textField: airport.displayCode,
    textSize: 12.0,
    textOffset: const Offset(0, -1.5),
    textColor: Colors.white.toHexStringRGB(),
    textHaloColor: AppColoursCommon.accentBlue.toHexStringRGB(),
    textHaloWidth: 2,
  );
}
