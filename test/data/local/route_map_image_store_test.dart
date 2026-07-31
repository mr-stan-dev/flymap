import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/data/local/route_map_image_store.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const points = [LatLng(51.47, -0.45), LatLng(40.64, -73.78)];

  test('weatherViewport matches the weather card square viewport', () {
    // The card fetches the cached base with weatherViewport() but draws the
    // route with its own buildViewport(540x540). If these drift, the cached
    // satellite base no longer lines up with the route/clouds drawn on top.
    final cached = RouteMapImageStore.weatherViewport(points);
    final drawn = StaticRouteMap.buildViewport(
      points: points,
      width: staticWeatherMapSize,
      height: staticWeatherMapSize,
    );
    expect(cached.center, drawn.center);
    expect(cached.zoom, drawn.zoom);
    expect(cached.width, drawn.width);
    expect(cached.height, drawn.height);
  });

  test('getOrFetchWeatherImage skips fetching for a degenerate route', () async {
    var called = false;
    final store = RouteMapImageStore(
      api: MapboxStaticImageApi(
        httpClient: MockClient((_) async {
          called = true;
          return http.Response('', 200);
        }),
        accessToken: 'test',
      ),
    );

    final file = await store.getOrFetchWeatherImage(
      flightId: 'f1',
      routePoints: const [LatLng(51.47, -0.45)],
    );

    expect(file, isNull);
    expect(called, isFalse, reason: 'one point cannot frame a map');
  });
}
