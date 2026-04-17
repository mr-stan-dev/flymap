import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/route_poi_summary.dart';

class HomeRoutePreviewStrip extends StatelessWidget {
  const HomeRoutePreviewStrip({
    required this.departureCode,
    required this.arrivalCode,
    required this.poi,
    super.key,
  });

  final String departureCode;
  final String arrivalCode;
  final List<RoutePoiSummary> poi;

  @override
  Widget build(BuildContext context) {
    final lineColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.32);
    final markerPositions = _markerPositions();

    return SizedBox(
      height: 42,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoutePreviewPainter(color: lineColor),
                ),
              ),
              Positioned(
                left: 0,
                top: 4,
                child: _AirportEndpointMarker(code: departureCode),
              ),
              for (var i = 0; i < poi.length; i++)
                Positioned(
                  left: width * markerPositions[i] - 12,
                  top: 4,
                  child: _PoiRouteMarker(type: poi[i].type),
                ),
              Positioned(
                right: 0,
                top: 4,
                child: _AirportEndpointMarker(code: arrivalCode),
              ),
            ],
          );
        },
      ),
    );
  }

  List<double> _markerPositions() {
    if (poi.isEmpty) return const [];
    final raw = poi.map((item) => item.routeProgress ?? 0.5).toList();
    final adjusted = <double>[];
    const minX = 0.18;
    const maxX = 0.82;
    const minGap = 0.14;

    for (final progress in raw) {
      var next = progress.clamp(minX, maxX);
      if (adjusted.isNotEmpty && next - adjusted.last < minGap) {
        next = (adjusted.last + minGap).clamp(minX, maxX);
      }
      adjusted.add(next);
    }

    for (var i = adjusted.length - 2; i >= 0; i--) {
      if (adjusted[i + 1] - adjusted[i] < minGap) {
        adjusted[i] = (adjusted[i + 1] - minGap).clamp(minX, maxX);
      }
    }
    return adjusted;
  }
}

class _AirportEndpointMarker extends StatelessWidget {
  const _AirportEndpointMarker({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Image.asset(
          'assets/images/poi/airport.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 3),
        Text(
          code,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PoiRouteMarker extends StatelessWidget {
  const _PoiRouteMarker({required this.type});

  final FlightPoiType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Image.asset(_iconAssetPathForType(type), fit: BoxFit.contain),
    );
  }

  String _iconAssetPathForType(FlightPoiType type) => switch (type) {
    FlightPoiType.city => 'assets/images/poi/city.png',
    FlightPoiType.river => 'assets/images/poi/river.png',
    FlightPoiType.island => 'assets/images/poi/island.png',
    FlightPoiType.airport => 'assets/images/poi/airport.png',
    FlightPoiType.mountain => 'assets/images/poi/mountain.png',
    FlightPoiType.lake => 'assets/images/poi/lake.png',
    FlightPoiType.volcano => 'assets/images/poi/volcano.png',
    FlightPoiType.pass => 'assets/images/poi/mountain.png',
    FlightPoiType.bay => 'assets/images/poi/bay.png',
    FlightPoiType.waterfall => 'assets/images/poi/waterfall.png',
    FlightPoiType.glacier => 'assets/images/poi/glacier.png',
    FlightPoiType.desert => 'assets/images/poi/desert.png',
    FlightPoiType.sea => 'assets/images/poi/sea.png',
    FlightPoiType.region => 'assets/images/poi/region.png',
    FlightPoiType.unknown => 'assets/images/poi/unknown.png',
  };
}

class _RoutePreviewPainter extends CustomPainter {
  const _RoutePreviewPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final y = size.height * 0.38;
    final path = Path()
      ..moveTo(12, y)
      ..lineTo(size.width - 12, y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
