import 'package:flutter/material.dart';

enum MetricTrend { up, down, steady }

class FlightMetricRow extends StatelessWidget {
  const FlightMetricRow({
    required this.name,
    required this.value,
    required this.unit,
    required this.color,
    this.trend = MetricTrend.steady,
    super.key,
  });

  final String name;
  final String value;
  final String unit;
  final Color color;
  final MetricTrend trend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? color.withValues(alpha: 0.1)
        : color.withValues(alpha: 0.05);
    final borderColor = isDark
        ? color.withValues(alpha: 0.3)
        : color.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _trendIcon(trend),
                size: 14,
                color: color.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _trendIcon(MetricTrend trend) {
    switch (trend) {
      case MetricTrend.up:
        return Icons.north_rounded;
      case MetricTrend.down:
        return Icons.south_rounded;
      case MetricTrend.steady:
        return Icons.east_rounded;
    }
  }
}
