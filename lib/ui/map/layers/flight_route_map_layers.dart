import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/map/layers/airports_layer.dart';
import 'package:flymap/ui/map/layers/corridor_layer.dart';
import 'package:flymap/ui/map/layers/dimming_layer.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightRouteMapLayers {
  const FlightRouteMapLayers._();

  static Future<void> add({
    required MapLibreMapController controller,
    required FlightRoute route,
    bool includeCorridor = true,
    bool includeDimming = true,
    bool includeAirports = true,
    String dashedPathSourceId = 'flight-route-path-source',
    String dashedPathLayerId = 'flight-route-path-layer',
  }) async {
    if (includeDimming) {
      await DimmingLayer(route.corridor).add(controller);
    }
    if (includeCorridor) {
      await CorridorLayer(route.corridor).add(controller);
    }

    await _addDashedRoutePath(
      controller: controller,
      route: route,
      sourceId: dashedPathSourceId,
      layerId: dashedPathLayerId,
    );

    if (includeAirports) {
      await AirportsLayer(
        departure: route.departure,
        arrival: route.arrival,
      ).add(controller);
    }
  }

  static Future<void> _addDashedRoutePath({
    required MapLibreMapController controller,
    required FlightRoute route,
    required String sourceId,
    required String layerId,
  }) async {
    final routePoints = _routePoints(route);
    if (routePoints.length < 2) return;

    final routeGeoJson = <String, dynamic>{
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': <String, dynamic>{
            'type': 'LineString',
            'coordinates': routePoints
                .map((point) => [point.longitude, point.latitude])
                .toList(),
          },
        },
      ],
    };

    await controller.addGeoJsonSource(sourceId, routeGeoJson);
    await controller.addLineLayer(
      sourceId,
      layerId,
      LineLayerProperties(
        lineColor: AppColoursCommon.brandTeal.toHexStringRGB(),
        lineWidth: 2,
        lineOpacity: 0.75,
        lineJoin: 'round',
        lineCap: 'round',
        lineDasharray: [1.2, 1.8],
      ),
    );
  }

  static List<ll.LatLng> _routePoints(FlightRoute route) {
    if (route.waypoints.length >= 2) {
      return route.waypoints;
    }
    return [route.departure.latLon, route.arrival.latLon];
  }
}
