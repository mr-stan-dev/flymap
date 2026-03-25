import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class GpsAccuracyBanner extends StatelessWidget {
  const GpsAccuracyBanner({required this.accuracy, super.key});

  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final status = _status(context, accuracy);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gps_fixed, size: 14, color: status.color),
          const SizedBox(width: 8),
          Text(
            'GPS Accuracy: ${status.label} (±${accuracy.toStringAsFixed(0)}m)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: status.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _GpsAccuracyStatus _status(BuildContext context, double value) {
    if (value < 10) {
      return _GpsAccuracyStatus('Excellent', DsSemanticColors.success(context));
    }
    if (value < 25) {
      return _GpsAccuracyStatus('Good', DsSemanticColors.warning(context));
    }
    return _GpsAccuracyStatus('Poor', DsSemanticColors.error(context));
  }
}

class _GpsAccuracyStatus {
  const _GpsAccuracyStatus(this.label, this.color);

  final String label;
  final Color color;
}
