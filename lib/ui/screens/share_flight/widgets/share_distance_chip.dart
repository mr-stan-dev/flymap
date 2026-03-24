import 'package:flutter/material.dart';

const double shareDistanceChipWidth = 184;
const double shareDistanceChipHeight = 58;

class ShareDistanceChip extends StatelessWidget {
  const ShareDistanceChip({required this.distanceKm, super.key});

  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final distanceLabel = '${distanceKm.toStringAsFixed(0)} km';

    return Container(
      width: shareDistanceChipWidth,
      height: shareDistanceChipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A2540).withValues(alpha: 0.88),
            const Color(0xFF1168A6).withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
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
            'Flight distance',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
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
                color: Colors.white.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 6),
              Text(
                distanceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
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
