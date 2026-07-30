import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/ui/screens/settings/distance_unit_context.dart';
import 'package:flymap/utils/duration_format_utils.dart';
import 'package:flymap/ui/screens/settings/date_display_format_context.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

class FlightSummaryCard extends StatelessWidget {
  final FlightSummary summary;
  final bool showBorder;

  /// The airport pair row. Off in the airport-pair search results, where all
  /// candidates share the same route shown once in the header.
  final bool showAirports;

  /// The scheduled date/time row. Off in the flight-pick step, where the
  /// date is chosen on the dedicated travel-date step afterwards.
  final bool showSchedule;
  final Widget? trailing;

  const FlightSummaryCard({
    super.key,
    required this.summary,
    this.showBorder = true,
    this.showAirports = true,
    this.showSchedule = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final departure = summary.departure;
    final arrival = summary.arrival;
    final airlineLabel = (summary.airlineName?.isNotEmpty == true)
        ? summary.airlineName!
        : (summary.airlineCode?.isNotEmpty == true
              ? summary.airlineCode!
              : null);
    final facts = _buildFacts(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: showBorder
            ? BorderSide(color: colorScheme.outlineVariant, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSchedule && summary.isUpcoming) ...[
              _ScheduledDateRow(summary: summary),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: airlineLabel != null
                      ? Text(
                          airlineLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        summary.flightNumber ?? '',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ],
            ),
            if (showAirports) ...[
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AirportInfo(
                      code: departure?.displayCode ?? '-',
                      name: departure?.nameShort,
                      city: departure?.city,
                      country: departure?.countryCode,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 56,
                      height: 30,
                      child: _RouteArcDivider(),
                    ),
                  ),
                  Expanded(
                    child: _AirportInfo(
                      code: arrival?.displayCode ?? '-',
                      name: arrival?.nameShort,
                      city: arrival?.city,
                      country: arrival?.countryCode,
                      crossAxisAlignment: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
            ],
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 14),
              _FactsRow(facts: facts),
            ],
          ],
        ),
      ),
    );
  }

  /// Recorded-flight facts: duration, distance, aircraft type. The flight
  /// date is deliberately NOT shown — the server caches summaries for up to
  /// 30 days, so it can be stale enough to confuse.
  List<String> _buildFacts(BuildContext context) {
    final durationMinutes = summary.displayActualDurationMinutes;
    final duration = durationMinutes == null
        ? null
        : DurationFormatUtils.formatApprox(context, durationMinutes);
    final distanceKm = summary.displayActualDistanceKm;
    final aircraftType = summary.aircraftType;
    return [
      if (duration != null) duration,
      if (distanceKm != null)
        UnitFormatUtils.formatDistanceApprox(
          distanceKm.toDouble(),
          context.distanceUnit,
        ),
      if (aircraftType != null && aircraftType.isNotEmpty) aircraftType,
    ];
  }
}

/// Scheduled departure date + local time — the key differentiator when the
/// user is picking their flight among identical dated departures.
class _ScheduledDateRow extends StatelessWidget {
  const _ScheduledDateRow({required this.summary});

  final FlightSummary summary;

  @override
  Widget build(BuildContext context) {
    final travelDate = summary.travelDateLocal;
    if (travelDate == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(Icons.event_rounded, size: 18, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          TravelDateFormatUtils.formatDateWithOptionalTime(
            travelDate,
            summary.scheduledDepartureLocal,
            context.dateDisplayFormat,
          ),
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      facts.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Small dashed arc with a plane at its apex, connecting the airport pair —
/// a miniature of the share/home card route styling.
class _RouteArcDivider extends StatelessWidget {
  const _RouteArcDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(size: Size.infinite, painter: _RouteArcPainter(color)),
        Transform.rotate(
          angle: math.pi / 2,
          child: Icon(Icons.flight, size: 16, color: color),
        ),
      ],
    );
  }
}

class _RouteArcPainter extends CustomPainter {
  const _RouteArcPainter(this.color);

  final Color color;

  static const double _dashLength = 4.0;
  static const double _dashGap = 3.5;
  static const double _planeGap = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(0, size.height * 0.85);
    final end = Offset(size.width, size.height * 0.85);
    final control = Offset(size.width / 2, -size.height * 0.35);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      final gapStart = (metric.length - _planeGap) / 2;
      final gapEnd = gapStart + _planeGap;
      var distance = 0.0;
      while (distance < metric.length) {
        final dashEnd = math.min(distance + _dashLength, metric.length);
        if (dashEnd <= gapStart || distance >= gapEnd) {
          canvas.drawPath(metric.extractPath(distance, dashEnd), paint);
        }
        distance += _dashLength + _dashGap;
      }
    }

    canvas.drawCircle(start, 2.2, Paint()..color = color);
    canvas.drawCircle(end, 2.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RouteArcPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AirportInfo extends StatelessWidget {
  final String code;
  final String? name;
  final String? city;
  final String? country;
  final CrossAxisAlignment crossAxisAlignment;

  const _AirportInfo({
    required this.code,
    this.name,
    this.city,
    this.country,
    required this.crossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final hasCityOrCountry =
        (city != null && city!.isNotEmpty) ||
        (country != null && country!.isNotEmpty);

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          code,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (hasCityOrCountry)
          Text(
            [
              if (city?.isNotEmpty == true) city,
              if (country?.isNotEmpty == true) country,
            ].join(', '),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (name != null && name!.isNotEmpty && name != code)
          Text(
            name!,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
