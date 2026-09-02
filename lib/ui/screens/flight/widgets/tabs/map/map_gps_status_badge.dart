import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_map_position.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_telemetry.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/day_night/route_sun_event_forecast.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/widgets/map_sun_event_hint.dart';

class MapGpsStatusBadge extends StatelessWidget {
  const MapGpsStatusBadge({
    required this.gpsStatus,
    required this.gpsData,
    this.mapPosition,
    this.sunEventForecast,
    this.onHelpTap,
    super.key,
  });

  final GpsStatus gpsStatus;
  final GpsData? gpsData;
  final FlightMapPosition? mapPosition;
  final RouteSunEventForecast? sunEventForecast;
  final VoidCallback? onHelpTap;

  @override
  Widget build(BuildContext context) {
    final view = _statusView(context);
    final telemetryLabel = _telemetryLabel();
    final hasDetails = telemetryLabel != null || sunEventForecast != null;

    return AnimatedContainer(
      duration: DsMotion.normal,
      curve: DsMotion.fastInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DsRadii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Flexible(
                child: Text(
                  view.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: view.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onHelpTap != null) ...[
                const SizedBox(width: DsSpacing.xxs),
                Tooltip(
                  message: context.t.flight.dashboard.gpsHelpTooltip,
                  child: InkWell(
                    onTap: onHelpTap,
                    borderRadius: BorderRadius.circular(DsRadii.pill),
                    child: Semantics(
                      button: true,
                      label: context.t.flight.dashboard.gpsHelpTooltip,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: view.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '?',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: view.color,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasDetails) const SizedBox(height: DsSpacing.xxs),
          if (telemetryLabel != null)
            Text(
              telemetryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.86),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (telemetryLabel != null && sunEventForecast != null)
            const SizedBox(height: 2),
          if (sunEventForecast != null)
            MapSunEventHint(forecast: sunEventForecast!, embedded: true),
        ],
      ),
    );
  }

  String? _telemetryLabel() {
    final live =
        gpsStatus == GpsStatus.gpsActive || gpsStatus == GpsStatus.weakSignal;
    final approximate =
        gpsStatus == GpsStatus.searching && mapPosition?.isApproximate == true;
    if (!live && !approximate) {
      return null;
    }
    if (gpsData?.speed == null || gpsData?.altitude == null) return null;

    final telemetry = InstrumentTelemetry.fromGpsData(gpsData);
    final label =
        '${telemetry.speedLabel} ${telemetry.speedUnit} '
        '• ${telemetry.altitudeLabel} ${telemetry.altitudeUnit}';
    return approximate
        ? '${t.flight.dashboard.gpsLastTelemetryShort} · $label'
        : label;
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
        final position = mapPosition;
        if (position != null && position.isApproximate) {
          final estimated =
              position.source == FlightMapPositionSource.estimated;
          return _MapGpsStatusView(
            icon: estimated
                ? Icons.near_me_outlined
                : Icons.location_history_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            label:
                '${estimated ? t.flight.dashboard.gpsEstimatedShort : t.flight.dashboard.gpsLastKnownShort}'
                ' · ${_compactAge(position.gpsAge)}',
          );
        }
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

  String _compactAge(Duration age) {
    final seconds = age.isNegative ? 0 : age.inSeconds;
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h';
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
