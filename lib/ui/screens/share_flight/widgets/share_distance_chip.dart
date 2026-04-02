import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';

const double shareDistanceChipWidth = 184;
const double shareDistanceChipHeight = 58;

class ShareDistanceChip extends StatelessWidget {
  const ShareDistanceChip({required this.distanceKm, super.key});

  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final distanceLabel = t.shareFlight.distanceKm(
      distance: distanceKm.toStringAsFixed(0),
    );

    return Container(
      width: shareDistanceChipWidth,
      height: shareDistanceChipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.8),
            colorScheme.primary.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            t.shareFlight.flightDistance,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.flight_takeoff,
                size: 14,
                color: colorScheme.onPrimary.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 6),
              Text(
                distanceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
