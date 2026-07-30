import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/cloud_field_builder.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/demo_cloud_story.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_map_painter.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:latlong2/latlong.dart';

/// One canned demo route: endpoints, its baked satellite asset (fetched for
/// exactly the viewport the arc produces at runtime), and the synthetic
/// weather story told along it.
class _DemoRoute {
  const _DemoRoute({
    required this.departureCode,
    required this.arrivalCode,
    required this.departure,
    required this.arrival,
    required this.routeKm,
    required this.asset,
    required this.story,
  });

  final String departureCode;
  final String arrivalCode;
  final LatLng departure;
  final LatLng arrival;
  final double routeKm;
  final String asset;
  final DemoCloudStory story;

  String get chipLabel => '$departureCode → $arrivalCode';
}

/// Weather payoff step: the real weather-map experience (same painter, same
/// cloud-field rasterizer as the Pro flight screen) running on canned
/// forecasts over bundled satellite images. Three rotating example routes +
/// an "Example" badge make it unmistakably a feature preview, not the
/// user's flight. Zero network, zero DI — the drifting clouds and the
/// plane crossing them ARE the pitch, right before the paywall.
class OnboardingWeatherPayoffStep extends StatefulWidget {
  const OnboardingWeatherPayoffStep({super.key});

  @override
  State<OnboardingWeatherPayoffStep> createState() =>
      _OnboardingWeatherPayoffStepState();
}

class _OnboardingWeatherPayoffStepState
    extends State<OnboardingWeatherPayoffStep>
    with SingleTickerProviderStateMixin {
  static const List<_DemoRoute> _routes = [
    _DemoRoute(
      departureCode: 'LHR',
      arrivalCode: 'FCO',
      departure: LatLng(51.4706, -0.461941),
      arrival: LatLng(41.800278, 12.238889),
      routeKm: 1435,
      asset: 'assets/images/onboarding_weather_map_lhr_fco.webp',
      // Broken clouds leaving England, the Alps in full view, a rain deck
      // rolling in on the approach to Rome.
      story: DemoCloudStory(
        hiddenAnchors: [
          (0.0, 55),
          (0.12, 45),
          (0.25, 24),
          (0.40, 12),
          (0.58, 10),
          (0.68, 30),
          (0.78, 82),
          (0.88, 68),
          (1.0, 45),
        ],
        rainCenter: 0.80,
        rainWidth: 0.09,
        rainAmplitudeMm: 2.4,
      ),
    ),
    _DemoRoute(
      departureCode: 'LAX',
      arrivalCode: 'JFK',
      departure: LatLng(33.9425, -118.408),
      arrival: LatLng(40.6413, -73.7781),
      routeKm: 3980,
      asset: 'assets/images/onboarding_weather_map_lax_jfk.webp',
      // Californian sun and clear Rockies, thickening over the plains,
      // rain on the East Coast approach.
      story: DemoCloudStory(
        hiddenAnchors: [
          (0.0, 8),
          (0.2, 10),
          (0.35, 22),
          (0.5, 40),
          (0.65, 55),
          (0.8, 75),
          (0.9, 85),
          (1.0, 60),
        ],
        rainCenter: 0.88,
        rainWidth: 0.07,
        rainAmplitudeMm: 2.0,
      ),
    ),
    _DemoRoute(
      departureCode: 'BER',
      arrivalCode: 'DXB',
      departure: LatLng(52.3667, 13.5033),
      arrival: LatLng(25.2528, 55.3644),
      routeKm: 4560,
      asset: 'assets/images/onboarding_weather_map_ber_dxb.webp',
      // Grey European start with rain over the Balkans, clearing over
      // Türkiye into cloudless desert skies at Dubai.
      story: DemoCloudStory(
        hiddenAnchors: [
          (0.0, 65),
          (0.15, 55),
          (0.3, 40),
          (0.45, 25),
          (0.6, 12),
          (0.8, 6),
          (1.0, 4),
        ],
        rainCenter: 0.12,
        rainWidth: 0.08,
        rainAmplitudeMm: 1.8,
      ),
    ),
  ];

  /// Same look as the flight-screen card: 24 crossfaded frames on a 180px
  /// field, 10s plane flight.
  static const int _cloudFrameCount = 24;
  static const int _cloudFieldResolution = 180;

  /// Any fixed instant works — the demo forecast is fully synthetic; a
  /// constant keeps every frame deterministic.
  static final DateTime _windowStart = DateTime.utc(2026, 5, 15, 9);
  static final DateTime _windowEnd = _windowStart.add(
    const Duration(hours: 2, minutes: 20),
  );

  late final AnimationController _plane = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  late final List<List<Offset>> _projectedRoutes;
  final List<List<ui.Image>> _cloudFrames = [
    for (final _ in _routes) <ui.Image>[],
  ];
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _projectedRoutes = [
      for (final route in _routes) _projectRoute(route),
    ];
    // The plane's landing IS the page-turn: each route plays one full
    // departure -> arrival flight, then the next example rotates in.
    _plane
      ..addStatusListener(_onFlightCompleted)
      ..forward();
    unawaited(_buildAllCloudFields());
  }

  void _onFlightCompleted(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _selected = (_selected + 1) % _routes.length);
    _plane.forward(from: 0);
  }

  List<Offset> _projectRoute(_DemoRoute route) {
    final arc = [
      for (var i = 0; i <= 32; i++)
        _slerp(route.departure, route.arrival, i / 32),
    ];
    final viewport = StaticRouteMap.buildViewport(
      points: arc,
      width: staticWeatherMapSize,
      height: staticWeatherMapSize,
    );
    return StaticRouteMap.projectRoute(
      points: arc,
      viewport: viewport,
    ).map((p) => p.toOffset()).toList(growable: false);
  }

  void _selectRoute(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    // The picked route starts its flight from the departure airport.
    _plane.forward(from: 0);
  }

  Future<void> _buildAllCloudFields() async {
    for (var i = 0; i < _routes.length; i++) {
      await _buildCloudField(i);
      if (!mounted) return;
    }
  }

  Future<void> _buildCloudField(int routeIndex) async {
    final route = _routes[routeIndex];
    final (:samples, :positions) = route.story.build(
      projectedRoute: _projectedRoutes[routeIndex],
      viewportSize: staticWeatherMapSize,
      windowStart: _windowStart,
      windowEnd: _windowEnd,
    );

    final builder = CloudFieldBuilder(
      samples: samples,
      positions: positions,
      viewportWidth: staticWeatherMapSize,
      viewportHeight: staticWeatherMapSize,
      fieldWidth: _cloudFieldResolution,
      fieldHeight: _cloudFieldResolution,
    );
    final images = <ui.Image>[];
    for (final buffer in builder.buildFrameBuffers(
      frameCount: _cloudFrameCount,
      start: _windowStart,
      end: _windowEnd,
    )) {
      images.add(
        await _decodeRgba(buffer, builder.fieldWidth, builder.fieldHeight),
      );
      await Future<void>.delayed(Duration.zero);
    }
    if (!mounted) {
      for (final image in images) {
        image.dispose();
      }
      return;
    }
    setState(() => _cloudFrames[routeIndex] = images);
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

  static LatLng _slerp(LatLng a, LatLng b, double f) {
    List<double> vector(LatLng p) {
      final phi = p.latitudeInRad;
      final lambda = p.longitudeInRad;
      return [
        math.cos(phi) * math.cos(lambda),
        math.cos(phi) * math.sin(lambda),
        math.sin(phi),
      ];
    }

    final v1 = vector(a);
    final v2 = vector(b);
    final dot = (v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]).clamp(
      -1.0,
      1.0,
    );
    final omega = math.acos(dot);
    if (omega < 1e-9) return f < 0.5 ? a : b;
    final sinOmega = math.sin(omega);
    final c1 = math.sin((1 - f) * omega) / sinOmega;
    final c2 = math.sin(f * omega) / sinOmega;
    final x = c1 * v1[0] + c2 * v2[0];
    final y = c1 * v1[1] + c2 * v2[1];
    final z = c1 * v1[2] + c2 * v2[2];
    const radToDeg = 180 / math.pi;
    return LatLng(
      math.atan2(z, math.sqrt(x * x + y * y)) * radToDeg,
      math.atan2(y, x) * radToDeg,
    );
  }

  @override
  void dispose() {
    _plane.dispose();
    for (final frames in _cloudFrames) {
      for (final image in frames) {
        image.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.t.onboarding.weatherPayoff;
    final route = _routes[_selected];

    return OnboardingStepScaffold(
      title: strings.title,
      subtitle: strings.subtitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: KeyedSubtree(
              key: ValueKey(_selected),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        route.asset,
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
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(color: Color(0x1F000000)),
                      ),
                      AnimatedBuilder(
                        animation: _plane,
                        builder: (context, _) => CustomPaint(
                          painter: WeatherMapPainter(
                            projectedRoute: _projectedRoutes[_selected],
                            cloudFrames: _cloudFrames[_selected],
                            routeKm: route.routeKm,
                            departureCode: route.departureCode,
                            arrivalCode: route.arrivalCode,
                            showClouds: true,
                            planeProgress: Curves.easeInOutSine.transform(
                              _plane.value,
                            ),
                          ),
                        ),
                      ),
                      // The demo disclaimer, always in view on the imagery.
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            strings.exampleBadge.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _routes.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _RouteChip(
                  label: _routes[i].chipLabel,
                  isSelected: i == _selected,
                  onTap: () => _selectRoute(i),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected ? colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}
