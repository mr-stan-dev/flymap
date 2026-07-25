import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/domain/policy/route_region_timeline_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/shared/region_artwork.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:flymap/utils/country_name_utils.dart';

class HomeRoutePreviewStrip extends StatelessWidget {
  const HomeRoutePreviewStrip({
    required this.departureCode,
    required this.arrivalCode,
    required this.departureCountryCode,
    required this.arrivalCountryCode,
    required this.regions,
    this.planeProgress,
    super.key,
  });

  final String departureCode;
  final String arrivalCode;

  /// ISO country codes for the two airports, rendered as a flag at each
  /// endpoint (matches the flag/nature circles in between); falls back to a
  /// generic airport icon when a code is missing.
  final String departureCountryCode;
  final String arrivalCountryCode;

  /// Regions crossed, as circles between the two airports (adaptive:
  /// countries abroad, natural features at home).
  final List<RouteRegionMarker> regions;

  /// 0..1 route progress for an in-progress flight: colors the traveled part
  /// of the line and places a plane marker on it. Null hides both.
  final double? planeProgress;

  @override
  Widget build(BuildContext context) {
    final lineColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.32);
    return SizedBox(
      height: 46,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 0.0;
          final offsets = _regionOffsets(width);
          final progress = planeProgress?.clamp(0.0, 1.0);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoutePreviewPainter(
                    color: lineColor,
                    progress: progress,
                    progressColor: AppColoursCommon.brandBlue,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 4,
                child: _AirportEndpointMarker(
                  code: departureCode,
                  countryCode: departureCountryCode,
                ),
              ),
              for (var i = 0; i < regions.length; i++)
                Positioned(
                  left: offsets[i],
                  top: 4,
                  child: _RegionRouteMarker(region: regions[i]),
                ),
              Positioned(
                right: 0,
                top: 4,
                child: _AirportEndpointMarker(
                  code: arrivalCode,
                  countryCode: arrivalCountryCode,
                ),
              ),
              if (progress != null)
                Positioned(
                  left: (12 + (width - 24) * progress) - _PlaneMarker.size / 2,
                  // Same row as the region/airport circles so the plane fully
                  // covers a marker it happens to pass over.
                  top: 4,
                  child: const _PlaneMarker(),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Left offsets (in px) for each middle marker's 48px labelled column.
  ///
  /// Spacing is enforced in PIXELS, not in route-progress fractions: markers
  /// are placed at their route position, then pushed apart so their centers are
  /// always at least a caption-width apart — otherwise two nearby regions'
  /// captions overlap ("BritishGreat…"). Assumes [regions] is route-ordered.
  List<double> _regionOffsets(double width) {
    if (regions.isEmpty || !width.isFinite || width <= 0) return const [];

    const slotWidth = 48.0;
    // Clear of the 44px airport endpoints at each edge.
    const endpointClearance = 46.0;
    // Min distance between two marker centers so captions never touch.
    const minGap = slotWidth + 6.0;

    final lo = endpointClearance + slotWidth / 2;
    final hi = width - endpointClearance - slotWidth / 2;
    if (hi <= lo) {
      // Too narrow to space them; stack at the start rather than crash.
      return List<double>.filled(regions.length, (lo - slotWidth / 2).clamp(0, width));
    }

    final centers = regions
        .map((r) => (width * r.routeProgress).clamp(lo, hi).toDouble())
        .toList();

    // Push right so no pair is closer than minGap...
    for (var i = 1; i < centers.length; i++) {
      if (centers[i] - centers[i - 1] < minGap) {
        centers[i] = (centers[i - 1] + minGap).clamp(lo, hi).toDouble();
      }
    }
    // ...then pull left for any that hit the right bound.
    for (var i = centers.length - 2; i >= 0; i--) {
      if (centers[i + 1] - centers[i] < minGap) {
        centers[i] = (centers[i + 1] - minGap).clamp(lo, hi).toDouble();
      }
    }

    return centers.map((c) => c - slotWidth / 2).toList();
  }
}

class _AirportEndpointMarker extends StatelessWidget {
  const _AirportEndpointMarker({required this.code, required this.countryCode});

  final String code;
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Circle width stays 24 (aligned to the line end), but the label is wider
    // and centered under it so 3-4 letter airport codes are never clipped.
    return SizedBox(
      width: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EndpointFlag(countryCode: countryCode),
          const SizedBox(height: 3),
          Text(
            code,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The airport endpoint icon with a small country-flag badge in the top-right
/// corner (about a quarter of the icon), so the country reads at a glance
/// without a full flag dominating — useful abroad, unobtrusive at home. The
/// badge is omitted when the country code is unknown.
class _EndpointFlag extends StatelessWidget {
  const _EndpointFlag({required this.countryCode});

  final String countryCode;

  static const double _iconSize = 24;
  static const double _badgeSize = 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final code = countryCode.trim();
    final hasFlag = code.length == 2;
    return SizedBox(
      width: _iconSize,
      height: _iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Image.asset(
            'assets/images/poi/airport.png',
            width: _iconSize,
            height: _iconSize,
            fit: BoxFit.contain,
          ),
          if (hasFlag)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // A ring in the card colour separates the badge from the icon.
                  border: Border.all(color: colorScheme.surface, width: 1.5),
                ),
                child: ClipOval(
                  child: CountryFlag.fromCountryCode(
                    code.toUpperCase(),
                    width: _badgeSize,
                    height: _badgeSize,
                    shape: const Rectangle(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RegionRouteMarker extends StatelessWidget {
  const _RegionRouteMarker({required this.region});

  final RouteRegionMarker region;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCountry = region.regionType == RouteRegionType.country;
    final label = _label();
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.18),
              ),
            ),
            // The shared region artwork: a flag for countries, a natural-
            // feature icon (sea, mountains, desert…) otherwise.
            child: RegionArtwork(
              regionName: region.name,
              regionType: region.regionType,
              size: 24,
              isCircle: true,
              flagOpacity: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              // Country codes read like the airport codes (bold); region names
              // are lighter so the two are visually distinct.
              fontWeight: isCountry ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// The caption under the circle: a 2-letter country code for countries
  /// (matching the airport endpoints), otherwise the region's name.
  String _label() {
    if (region.regionType == RouteRegionType.country) {
      final code = CountryNameUtils.toCode(
        region.name,
        languageCode: LocaleSettings.currentLocale.languageCode,
      );
      if (code != null) return code.toUpperCase();
    }
    return region.name;
  }
}

/// The plane marker for in-progress flights: same size and chrome as the
/// region/airport circles so it reads as part of the marker row and fully
/// covers any marker it overlaps.
class _PlaneMarker extends StatelessWidget {
  const _PlaneMarker();

  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: const RotatedBox(
        quarterTurns: 1,
        child: Icon(
          Icons.flight,
          size: size - 6,
          color: AppColoursCommon.brandBlue,
        ),
      ),
    );
  }
}

class _RoutePreviewPainter extends CustomPainter {
  const _RoutePreviewPainter({
    required this.color,
    required this.progress,
    required this.progressColor,
  });

  final Color color;
  final double? progress;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final y = size.height * 0.38;
    canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), paint);

    final traveled = progress;
    if (traveled != null && traveled > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final endX = 12 + (size.width - 24) * traveled;
      canvas.drawLine(Offset(12, y), Offset(endX, y), progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
