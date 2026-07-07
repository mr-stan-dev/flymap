import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/distance_unit_context.dart';
import 'package:flymap/utils/unit_format_utils.dart';

class RouteProgressCard extends StatelessWidget {
  const RouteProgressCard({
    required this.route,
    required this.coveredDistanceKm,
    this.isStale = false,
    super.key,
  });

  final FlightRoute route;
  final double coveredDistanceKm;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final totalKm = route.distanceInKm;
    final coveredKm = coveredDistanceKm.clamp(0.0, totalKm);
    final progress = totalKm > 0 ? (coveredKm / totalKm).clamp(0.0, 1.0) : 0.0;
    final remainingKm = (totalKm - coveredKm).clamp(0.0, totalKm);
    final unit = context.distanceUnit;
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
                context.t.flight.dashboard.routeProgress,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
          if (isStale) ...[
            const SizedBox(height: 6),
            Text(
              context.t.flight.dashboard.gpsShowingLastKnownData,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                  label: context.t.flight.dashboard.covered,
                  value: UnitFormatUtils.formatDistance(coveredKm, unit),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  label: context.t.flight.dashboard.remaining,
                  value: UnitFormatUtils.formatDistance(remainingKm, unit),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  label: context.t.flight.dashboard.total,
                  value: UnitFormatUtils.formatDistance(totalKm, unit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
