import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';

class RouteProgressCard extends StatelessWidget {
  const RouteProgressCard({
    required this.route,
    required this.gpsData,
    super.key,
  });

  static const _betweenAirportsToleranceMultiplier = 1.3;

  final FlightRoute route;
  final GpsData? gpsData;

  @override
  Widget build(BuildContext context) {
    final totalKm = route.distanceInKm;
    final progress = _estimateProgress();
    final coveredKm = progress * totalKm;
    final remainingKm = (totalKm - coveredKm).clamp(0, totalKm);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Route progress',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                route.departure.displayCode,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                route.arrival.displayCode,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Covered',
                  value: '${coveredKm.toStringAsFixed(0)} km',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  label: 'Remaining',
                  value: '${remainingKm.toStringAsFixed(0)} km',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  label: 'Total',
                  value: '${totalKm.toStringAsFixed(0)} km',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _estimateProgress() {
    final lat = gpsData?.latitude;
    final lon = gpsData?.longitude;
    if (lat == null || lon == null) return 0;

    final airportToAirportDistanceKm = route.distanceInKm;
    if (airportToAirportDistanceKm <= 0) return 0;

    final current = LatLng(lat, lon);
    final distanceToDepartureKm = MapUtils.distanceKm(
      departure: route.departure.latLon,
      arrival: current,
    );
    final distanceToArrivalKm = MapUtils.distanceKm(
      departure: current,
      arrival: route.arrival.latLon,
    );

    if (distanceToArrivalKm > distanceToDepartureKm) return 0;

    final span = distanceToDepartureKm + distanceToArrivalKm;
    if (span <= 0) return 0;
    final maxAllowedSpanKm =
        airportToAirportDistanceKm * _betweenAirportsToleranceMultiplier;
    if (span > maxAllowedSpanKm) return 0;

    return (distanceToDepartureKm / span).clamp(0.0, 1.0);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
