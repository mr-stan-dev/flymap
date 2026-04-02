import 'package:flutter/material.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class MapGpsStatusBadge extends StatelessWidget {
  const MapGpsStatusBadge({
    required this.gpsStatus,
    required this.gpsData,
    super.key,
  });

  final GpsStatus gpsStatus;
  final GpsData? gpsData;

  @override
  Widget build(BuildContext context) {
    final view = _statusView(context);

    return IgnorePointer(
      child: AnimatedContainer(
        duration: DsMotion.normal,
        curve: DsMotion.fastInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpacing.sm,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(DsRadii.pill),
          border: Border.all(color: view.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (view.searching)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation<Color>(view.color),
                ),
              )
            else
              Icon(view.icon, size: 14, color: view.color),
            const SizedBox(width: DsSpacing.xxs),
            Text(
              view.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: view.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _MapGpsStatusView _statusView(BuildContext context) {
    final t = context.t;
    final success = DsSemanticColors.success(context);
    final warning = DsSemanticColors.warning(context);
    final error = DsSemanticColors.error(context);
    final info = DsSemanticColors.info(context);

    switch (gpsStatus) {
      case GpsStatus.gpsActive:
      case GpsStatus.weakSignal:
        final quality = _signalQuality(gpsData?.accuracy);
        return _MapGpsStatusView(
          icon: Icons.gps_fixed_rounded,
          color: _qualityColor(
            quality,
            success: success,
            warning: warning,
            error: error,
          ),
          label: t.flight.dashboard.gpsQuality(
            quality: _qualityLabel(context, quality),
          ),
        );
      case GpsStatus.searching:
        return _MapGpsStatusView(
          icon: Icons.gps_not_fixed_rounded,
          color: info,
          label: t.flight.dashboard.gpsSearchingLabel,
          searching: true,
        );
      case GpsStatus.permissionsNotGranted:
        return _MapGpsStatusView(
          icon: Icons.location_disabled_rounded,
          color: warning,
          label: t.flight.dashboard.gpsPermissionNeededLabel,
        );
      case GpsStatus.off:
        return _MapGpsStatusView(
          icon: Icons.gps_off_rounded,
          color: error,
          label: t.flight.dashboard.gpsOffLabel,
        );
    }
  }

  _SignalQuality _signalQuality(double? accuracy) {
    if (accuracy == null) return _SignalQuality.bad;
    if (accuracy <= 15) return _SignalQuality.good;
    if (accuracy <= 40) return _SignalQuality.poor;
    return _SignalQuality.bad;
  }

  Color _qualityColor(
    _SignalQuality quality, {
    required Color success,
    required Color warning,
    required Color error,
  }) {
    switch (quality) {
      case _SignalQuality.good:
        return success;
      case _SignalQuality.poor:
        return warning;
      case _SignalQuality.bad:
        return error;
    }
  }

  String _qualityLabel(BuildContext context, _SignalQuality quality) {
    final t = context.t;
    switch (quality) {
      case _SignalQuality.good:
        return t.flight.dashboard.signalGood;
      case _SignalQuality.poor:
        return t.flight.dashboard.signalPoor;
      case _SignalQuality.bad:
        return t.flight.dashboard.signalBad;
    }
  }
}

class _MapGpsStatusView {
  const _MapGpsStatusView({
    required this.icon,
    required this.color,
    required this.label,
    this.searching = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool searching;
}

enum _SignalQuality { good, poor, bad }
