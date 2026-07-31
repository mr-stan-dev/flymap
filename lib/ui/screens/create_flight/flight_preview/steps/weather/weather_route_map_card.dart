import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/data/local/route_map_image_store.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/cloud_field_builder.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/demo_cloud_story.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_map_painter.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// The hero of the weather step: the real static map (same Mapbox imagery
/// as the share card, same portrait viewport math), the actual route drawn
/// from its waypoints, and a Windy-style continuous cloud layer rendered
/// from the forecast samples ([CloudFieldBuilder]). Pro sees the clouds and
/// the plane flying the route; the free teaser runs [isDemo] mode instead —
/// canned [DemoCloudStory] clouds + plane over the real route, labeled with
/// an EXAMPLE badge, no forecast fetched.
class WeatherRouteMapCard extends StatefulWidget {
  const WeatherRouteMapCard({
    required this.route,
    required this.samples,
    this.areaSamples = const <RouteCloudSample>[],
    required this.isProUser,
    this.isDemo = false,
    this.flightId,
    super.key,
  });

  final FlightRoute route;
  final List<RouteCloudSample> samples;

  /// Grid samples covering the rest of the card, so the cloud field spans
  /// the whole picture instead of a corridor-only band.
  final List<RouteCloudSample> areaSamples;
  final bool isProUser;

  /// Saved flight this card belongs to, when there is one. Its presence
  /// routes the satellite base through [RouteMapImageStore]'s per-flight disk
  /// cache (populated online at download), so the map still shows in airplane
  /// mode. Null during flight creation — no saved flight yet, so the card
  /// fetches the base live.
  final String? flightId;

  /// Teaser mode for free users: ignores [samples] and animates the canned
  /// [DemoCloudStory.generic] over the route, with an EXAMPLE badge and no
  /// lock strip (the caller renders its own upgrade CTA).
  final bool isDemo;

  @override
  State<WeatherRouteMapCard> createState() => _WeatherRouteMapCardState();
}

class _WeatherRouteMapCardState extends State<WeatherRouteMapCard>
    with TickerProviderStateMixin {
  /// Cloud-field frames spanning the flight; crossfaded by plane progress.
  static const int _cloudFrameCount = 24;

  /// ~2 viewport px per field cell — fine enough that the upscaled lattice
  /// stays invisible on tall phone screens. Affordable because the frames
  /// rasterize on a background isolate, not the UI thread.
  static const int _cloudFieldResolution = 270;

  late final AnimationController _plane = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  /// Fades the cloud layer in once its frames land — they arrive a beat
  /// after the map image (background rasterization), and without the fade
  /// the layer pops in like a glitch.
  late final AnimationController _cloudFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  late final List<LatLng> _routePoints;
  late final StaticMapViewport _viewport;
  late final List<Offset> _projectedRoute;
  late final List<RouteCloudSample> _cloudSamples;
  late final List<Offset> _projectedSamples;
  List<ui.Image> _cloudFrames = const [];

  /// True when rasterization threw — hides the loading chip so it can't
  /// spin forever; the card just stays cloudless (map still works).
  bool _cloudBuildFailed = false;
  Uint8List? _mapBytes;

  /// True once the static map fetch definitively failed (offline, no DI) —
  /// only then does the gradient stand in. While loading, the card shows a
  /// quiet placeholder instead of flashing the gradient.
  bool _mapFailed = false;

  /// Demo backdrop: one of the bundled onboarding satellite maps. The
  /// geography doesn't match the user's route, but behind the teaser blur
  /// it just reads as real imagery — richer than a flat gradient, still
  /// zero network.
  static const _demoMapAsset =
      'assets/images/onboarding_weather_map_lhr_fco.webp';

  @override
  void initState() {
    super.initState();
    final waypoints = widget.route.waypointLatLngs;
    _routePoints = waypoints.length >= 2
        ? waypoints
        : [widget.route.departure.latLon, widget.route.arrival.latLon];
    // Square framing: identical for horizontal and vertical routes, and
    // takes less vertical space than the share card's portrait.
    _viewport = StaticRouteMap.buildViewport(
      points: _routePoints,
      width: staticWeatherMapSize,
      height: staticWeatherMapSize,
    );
    _projectedRoute = StaticRouteMap.projectRoute(
      points: _routePoints,
      viewport: _viewport,
    ).map((p) => p.toOffset()).toList(growable: false);
    if (widget.isDemo) {
      // Canned story along the real route — no forecast data involved.
      final story = DemoCloudStory.generic.build(
        projectedRoute: _projectedRoute,
        viewportSize: staticWeatherMapSize,
      );
      _cloudSamples = story.samples;
      _projectedSamples = story.positions;
    } else {
      // Corridor + full-card grid rendered as one field.
      _cloudSamples = [...widget.samples, ...widget.areaSamples];
      _projectedSamples = StaticRouteMap.projectRoute(
        points: _cloudSamples.map((s) => s.latLon).toList(growable: false),
        viewport: _viewport,
      ).map((p) => p.toOffset()).toList(growable: false);
    }

    if (widget.isProUser || widget.isDemo) {
      _plane.repeat();
      unawaited(_buildCloudField());
    }
    _fetchMapImage();
  }

  /// Rasterizes the samples into continuous cloud frames on a background
  /// isolate (the field is pure math over plain data); the painter draws
  /// whatever is ready (nothing until then).
  Future<void> _buildCloudField() async {
    if (_cloudSamples.isEmpty) return;
    final corridor = widget.samples;
    final start = widget.isDemo
        ? DemoCloudStory.defaultWindowStart
        : (corridor.isNotEmpty ? corridor.first : _cloudSamples.first).timeUtc;
    final end = widget.isDemo
        ? DemoCloudStory.defaultWindowEnd
        : (corridor.isNotEmpty ? corridor.last : _cloudSamples.last).timeUtc;
    final builder = CloudFieldBuilder(
      samples: _cloudSamples,
      positions: _projectedSamples,
      viewportWidth: staticWeatherMapSize,
      viewportHeight: staticWeatherMapSize,
      fieldWidth: _cloudFieldResolution,
      fieldHeight: _cloudFieldResolution,
    );
    final frameCount = end.isAfter(start) ? _cloudFrameCount : 1;
    final List<Uint8List> buffers;
    try {
      buffers = await _rasterizeFrames(builder, frameCount, start, end);
    } catch (_) {
      // Degrade silently to a cloudless card — the map and route still
      // carry the step; the chip must not spin forever.
      if (mounted) setState(() => _cloudBuildFailed = true);
      return;
    }
    final images = <ui.Image>[];
    for (final buffer in buffers) {
      images.add(
        await _decodeRgba(buffer, builder.fieldWidth, builder.fieldHeight),
      );
    }
    if (!mounted) {
      for (final image in images) {
        image.dispose();
      }
      return;
    }
    setState(() => _cloudFrames = images);
    _cloudFade.forward();
  }

  /// Static on purpose: an instance-method closure links the State (with
  /// its ticker) into the isolate message via the captured context and
  /// [Isolate.run] rejects it as unsendable — a static scope holds only the
  /// plain-data arguments.
  static Future<List<Uint8List>> _rasterizeFrames(
    CloudFieldBuilder builder,
    int frameCount,
    DateTime start,
    DateTime end,
  ) {
    return Isolate.run(
      () => builder
          .buildFrameBuffers(frameCount: frameCount, start: start, end: end)
          .toList(growable: false),
    );
  }

  Future<ui.Image> _decodeRgba(Uint8List rgba, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<void> _fetchMapImage() async {
    // Demo mode sits behind the teaser blur — don't spend a Mapbox call on
    // imagery nobody can see; the bundled onboarding map stands in.
    if (widget.isDemo) {
      _mapFailed = true;
      return;
    }
    // Saved flight: read the satellite base from the per-flight disk cache
    // (fetched online at download). This is the only path that works in
    // airplane mode — a cache hit returns without touching the network; a
    // miss on a legacy flight opened online fetches and caches for next time.
    final flightId = widget.flightId;
    if (flightId != null && GetIt.I.isRegistered<RouteMapImageStore>()) {
      try {
        final file = await GetIt.I
            .get<RouteMapImageStore>()
            .getOrFetchWeatherImage(
              flightId: flightId,
              routePoints: _routePoints,
            );
        final bytes = file == null ? null : await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          if (bytes == null || bytes.isEmpty) {
            _mapFailed = true;
          } else {
            _mapBytes = bytes;
          }
        });
      } catch (_) {
        if (mounted) setState(() => _mapFailed = true);
      }
      return;
    }
    // Flight creation (no saved flight yet) or tests without DI: fetch the
    // base live, falling back to the gradient when there's no network/DI.
    if (!GetIt.I.isRegistered<MapboxStaticImageApi>()) {
      _mapFailed = true;
      return;
    }
    try {
      final bytes = await GetIt.I
          .get<MapboxStaticImageApi>()
          .fetchStaticMapImage(
            center: _viewport.center,
            zoom: _viewport.zoom,
            width: staticWeatherMapSize.toInt(),
            height: staticWeatherMapSize.toInt(),
          );
      if (!mounted) return;
      setState(() {
        if (bytes == null) {
          _mapFailed = true;
        } else {
          _mapBytes = bytes;
        }
      });
    } catch (_) {
      // Fall back to the gradient background — the overlay still
      // communicates.
      if (mounted) setState(() => _mapFailed = true);
    }
  }

  @override
  void dispose() {
    _plane.dispose();
    _cloudFade.dispose();
    for (final image in _cloudFrames) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final colorScheme = Theme.of(context).colorScheme;
    final bytes = _mapBytes;
    final showWeather = widget.isProUser || widget.isDemo;
    // While the imagery loads, hold everything back — a quiet placeholder
    // beats a blue flash, and route/clouds popping in with the map reads
    // as one transition instead of two.
    final isMapLoading = bytes == null && !_mapFailed;

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: widget.isDemo
                  ? Image.asset(
                      _demoMapAsset,
                      key: const ValueKey('demo'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF16324F), Color(0xFF3E6C99)],
                          ),
                        ),
                      ),
                    )
                  : bytes != null
                  ? Image.memory(
                      bytes,
                      key: const ValueKey('map'),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : _mapFailed
                  ? const DecoratedBox(
                      key: ValueKey('fallback'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF16324F), Color(0xFF3E6C99)],
                        ),
                      ),
                    )
                  : DecoratedBox(
                      key: const ValueKey('loading'),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
            ),
            if (!isMapLoading) ...[
              // Slight scrim so the white route/clouds read on bright
              // imagery.
              const DecoratedBox(
                decoration: BoxDecoration(color: Color(0x1F000000)),
              ),
              AnimatedBuilder(
                animation: Listenable.merge([_plane, _cloudFade]),
                builder: (context, _) => CustomPaint(
                  painter: WeatherMapPainter(
                    projectedRoute: _projectedRoute,
                    cloudFrames: _cloudFrames,
                    routeKm: widget.route.displayDistanceKm.toDouble(),
                    departureCode: widget.route.departure.displayCode,
                    arrivalCode: widget.route.arrival.displayCode,
                    showClouds: showWeather,
                    planeProgress: showWeather
                        ? Curves.easeInOutSine.transform(_plane.value)
                        : null,
                    cloudOpacity: Curves.easeOut.transform(_cloudFade.value),
                  ),
                ),
              ),
              // While the cloud field rasterizes, say so — the map lands
              // first and silent late-arriving clouds read as a glitch.
              Positioned(
                top: 10,
                right: 10,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child:
                      showWeather &&
                          _cloudFrames.isEmpty &&
                          !_cloudBuildFailed &&
                          _cloudSamples.isNotEmpty
                      ? const _CloudsLoadingChip()
                      : const SizedBox.shrink(),
                ),
              ),
            ],
            if (!widget.isProUser && !widget.isDemo)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xB3000000)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          t.proTeaserTitle,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tiny status pill in the card corner while the cloud field rasterizes —
/// the map and route land first, and this names the one thing still coming.
class _CloudsLoadingChip extends StatelessWidget {
  const _CloudsLoadingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 11,
            height: 11,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            context.t.createFlight.weather.cloudsLoading,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
