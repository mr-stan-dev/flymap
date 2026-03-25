import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/entity/gps_data.dart';

class GpsLiveStatusCard extends StatefulWidget {
  const GpsLiveStatusCard({
    required this.gpsStatus,
    required this.gpsData,
    required this.gpsUpdateTick,
    super.key,
  });

  final GpsStatus gpsStatus;
  final GpsData? gpsData;
  final int gpsUpdateTick;

  @override
  State<GpsLiveStatusCard> createState() => _GpsLiveStatusCardState();
}

class _GpsLiveStatusCardState extends State<GpsLiveStatusCard> {
  DateTime? _lastFixAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.gpsData != null) {
      _lastFixAt = DateTime.now();
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant GpsLiveStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gpsData != null &&
        oldWidget.gpsUpdateTick != widget.gpsUpdateTick) {
      _lastFixAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final age = _lastFixAt == null ? null : now.difference(_lastFixAt!);
    final view = _statusData(context, age);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: view.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: view.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: view.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(view.icon, color: view.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: view.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  view.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: view.color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_showSignalStrength)
            _SignalStrengthBadge(
              quality: _signalQuality(
                status: widget.gpsStatus,
                accuracy: widget.gpsData?.accuracy,
              ),
            ),
        ],
      ),
    );
  }

  bool get _showSignalStrength =>
      widget.gpsStatus == GpsStatus.gpsActive ||
      widget.gpsStatus == GpsStatus.weakSignal ||
      widget.gpsStatus == GpsStatus.searching;

  _SignalQuality _signalQuality({
    required GpsStatus status,
    required double? accuracy,
  }) {
    if (status == GpsStatus.searching) return _SignalQuality.searching;
    if (accuracy == null) return _SignalQuality.bad;
    if (accuracy <= 15) return _SignalQuality.good;
    if (accuracy <= 40) return _SignalQuality.poor;
    return _SignalQuality.bad;
  }

  _GpsStatusViewData _statusData(BuildContext context, Duration? age) {
    final successColor = DsSemanticColors.success(context);
    final warningColor = DsSemanticColors.warning(context);
    final infoColor = DsSemanticColors.info(context);
    final errorColor = DsSemanticColors.error(context);

    switch (widget.gpsStatus) {
      case GpsStatus.off:
        return _GpsStatusViewData(
          color: errorColor,
          icon: Icons.gps_off_rounded,
          title: 'GPS off',
          subtitle: 'Enable location services to start tracking.',
        );
      case GpsStatus.permissionsNotGranted:
        return _GpsStatusViewData(
          color: warningColor,
          icon: Icons.location_disabled_rounded,
          title: 'Location permission required',
          subtitle: 'Grant permission to access live flight telemetry.',
        );
      case GpsStatus.searching:
        return _GpsStatusViewData(
          color: infoColor,
          icon: Icons.gps_not_fixed_rounded,
          title: 'Searching for GPS',
          subtitle: 'Looking for a reliable signal',
        );
      case GpsStatus.weakSignal:
        return _GpsStatusViewData(
          color: warningColor,
          icon: Icons.network_check_rounded,
          title: 'Weak GPS signal',
          subtitle: age == null
              ? 'Signal is unstable. Keep device in open sky.'
              : 'Signal unstable. Last fix ${_ageLabel(age)}.',
        );
      case GpsStatus.gpsActive:
        return _GpsStatusViewData(
          color: successColor,
          icon: Icons.gps_fixed_rounded,
          title: 'GPS active',
          subtitle: age == null
              ? 'Receiving live telemetry.'
              : 'Last GPS update ${_ageLabel(age)}.',
        );
    }
  }

  String _ageLabel(Duration age) {
    if (age.inSeconds < 1) return 'just now';
    if (age.inSeconds < 60) return '${age.inSeconds}s ago';
    final minutes = age.inMinutes;
    return '${minutes}m ago';
  }
}

class _GpsStatusViewData {
  const _GpsStatusViewData({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
}

enum _SignalQuality { good, poor, bad, searching }

class _SignalStrengthBadge extends StatelessWidget {
  const _SignalStrengthBadge({required this.quality});

  final _SignalQuality quality;

  @override
  Widget build(BuildContext context) {
    final color = _colorForQuality(context, quality);
    final filledBars = _filledBars(quality);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (index) {
            final heights = [5.0, 8.0, 11.0, 14.0];
            return Container(
              width: 4,
              height: heights[index],
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 2,
                bottom: index == 3 ? 0 : 1,
              ),
              decoration: BoxDecoration(
                color: index < filledBars
                    ? color
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _labelForQuality(quality),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  int _filledBars(_SignalQuality quality) {
    switch (quality) {
      case _SignalQuality.good:
        return 4;
      case _SignalQuality.poor:
        return 2;
      case _SignalQuality.bad:
        return 1;
      case _SignalQuality.searching:
        return 0;
    }
  }

  String _labelForQuality(_SignalQuality quality) {
    switch (quality) {
      case _SignalQuality.good:
        return 'Good';
      case _SignalQuality.poor:
        return 'Poor';
      case _SignalQuality.bad:
        return 'Bad';
      case _SignalQuality.searching:
        return 'Searching';
    }
  }

  Color _colorForQuality(BuildContext context, _SignalQuality quality) {
    switch (quality) {
      case _SignalQuality.good:
        return DsSemanticColors.success(context);
      case _SignalQuality.poor:
        return DsSemanticColors.warning(context);
      case _SignalQuality.bad:
        return DsSemanticColors.error(context);
      case _SignalQuality.searching:
        return DsSemanticColors.info(context);
    }
  }
}
