import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/data/flight_video/video_encoder.dart';
import 'package:flymap/data/local/route_map_image_store.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_renderer.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.temporaryPath);

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}

/// Records which flight the share asked to cache, and returns no file so the
/// test needs no on-disk image — enough to prove the routing.
class _RecordingImageStore extends RouteMapImageStore {
  _RecordingImageStore()
    : super(
        api: MapboxStaticImageApi(
          httpClient: MockClient((_) async => http.Response('unused', 500)),
          accessToken: 'test',
        ),
      );

  String? requestedFlightId;

  @override
  Future<File?> getOrFetchWeatherImage({
    required String flightId,
    required List<LatLng> routePoints,
  }) async {
    requestedFlightId = flightId;
    return null;
  }
}

class _FakeEncoder implements FlightVideoEncoder {
  int? width;
  int? height;
  int? fps;
  final frames = <int>[];
  bool finished = false;
  bool aborted = false;

  @override
  Future<void> setup({
    required int width,
    required int height,
    required int fps,
    required int bitrate,
    required String filePath,
  }) async {
    this.width = width;
    this.height = height;
    this.fps = fps;
  }

  @override
  Future<void> appendFrame(Uint8List rawRgba) async {
    frames.add(rawRgba.length);
  }

  @override
  Future<void> finish() async {
    finished = true;
  }

  @override
  Future<void> abort() async {
    aborted = true;
  }
}

FlightRoute _route() {
  const departure = Airport(
    name: 'Bristol',
    city: 'Bristol',
    countryCode: 'GB',
    latLon: LatLng(51.38, -2.72),
    iataCode: 'BRS',
    icaoCode: 'EGGD',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Krakow',
    city: 'Krakow',
    countryCode: 'PL',
    latLon: LatLng(50.08, 19.78),
    iataCode: 'KRK',
    icaoCode: 'EPKK',
    wikipediaUrl: '',
  );
  return const FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [],
    corridor: [],
  );
}

FlightWeather _weather() {
  AirportWeather airport() => AirportWeather(
    timeUtc: DateTime.utc(2026, 8, 3, 8),
    utcOffsetMinutes: 120,
    temperatureC: 21,
    windSpeedMs: 4,
    cloudCoverPercent: 40,
    symbolCode: 'partlycloudy_day',
  );
  return FlightWeather(
    departure: airport(),
    arrival: airport(),
    samples: [
      for (var i = 1; i <= 5; i++)
        RouteCloudSample(
          routeProgress: i / 6,
          latLon: LatLng(50.5, -2 + i * 4),
          timeUtc: DateTime.utc(2026, 8, 3, 8, i * 10),
          cloudLowPercent: 60,
          cloudMidPercent: 10,
          cloudHighPercent: 20,
        ),
    ],
    fetchedAt: DateTime.utc(2026, 8, 1),
    isTimeEstimated: false,
  );
}

const _data = WeatherShareData(
  headline: 'BRS → KRK',
  subtitle: 'FR6221 · Aug 3',
  departure: WeatherShareAirport(
    label: 'Departure',
    code: 'BRS',
    city: 'Bristol',
    emoji: '⛅',
    temperatureText: '21°',
    timeText: '10:00',
  ),
  arrival: WeatherShareAirport(
    label: 'Arrival',
    code: 'KRK',
    city: 'Krakow',
    emoji: '⛅',
    temperatureText: '21°',
  ),
  watermark: 'flymap.app',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory temporaryDirectory;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'weather-share-test',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      temporaryDirectory.path,
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await temporaryDirectory.delete(recursive: true);
  });

  WeatherShareService service(_FakeEncoder encoder) {
    return WeatherShareService(
      // Map fetch fails -> gradient fallback; no network in tests.
      mapApi: MapboxStaticImageApi(
        httpClient: MockClient((_) async => http.Response('nope', 500)),
        accessToken: 'test',
      ),
      encoder: encoder,
    );
  }

  test('exports the static story card as a non-trivial PNG', () async {
    final encoder = _FakeEncoder();
    final shareService = service(encoder);
    final renderer = await shareService.buildRenderer(
      route: _route(),
      weather: _weather(),
      data: _data,
    );

    final path = await shareService.exportImage(renderer);
    shareService.disposeRenderer(renderer);

    final file = File(path);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(10000));
    expect(path, endsWith('.png'));
  });

  test('exports video frames sized 720x1280 through the encoder', () async {
    final encoder = _FakeEncoder();
    final shareService = service(encoder);
    final renderer = await shareService.buildRenderer(
      route: _route(),
      weather: _weather(),
      data: _data,
    );

    final path = await shareService.exportVideo(
      renderer,
      fps: 5,
      seconds: 1,
    );
    shareService.disposeRenderer(renderer);

    // Video renders at 2/3 scale for speed; layout is unchanged.
    expect(encoder.width, 720);
    expect(encoder.height, 1280);
    expect(encoder.fps, 5);
    expect(encoder.frames, hasLength(5));
    // Raw RGBA frames of the scaled story canvas.
    expect(encoder.frames.first, 720 * 1280 * 4);
    expect(encoder.finished, isTrue);
    expect(encoder.aborted, isFalse);
    expect(path, endsWith('.mp4'));
  });

  test('a saved flight shares from the offline cache, not the network',
      () async {
    // Regression: the share fetched the map base from the network, so an
    // airplane-mode share of a saved flight lost the satellite map. With a
    // flightId it must go through the per-flight cache instead.
    var networkCalled = false;
    final store = _RecordingImageStore();
    final shareService = WeatherShareService(
      mapApi: MapboxStaticImageApi(
        httpClient: MockClient((_) async {
          networkCalled = true;
          return http.Response('nope', 500);
        }),
        accessToken: 'test',
      ),
      encoder: _FakeEncoder(),
      imageStore: store,
    );

    final renderer = await shareService.buildRenderer(
      route: _route(),
      weather: _weather(),
      data: _data,
      flightId: 'flight-1',
    );
    shareService.disposeRenderer(renderer);

    expect(store.requestedFlightId, 'flight-1');
    expect(networkCalled, isFalse, reason: 'cache path, no live fetch');
  });
}
