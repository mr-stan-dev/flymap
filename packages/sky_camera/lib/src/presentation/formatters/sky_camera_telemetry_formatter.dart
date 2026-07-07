import 'package:flutter/material.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';
import 'package:sky_camera/src/presentation/sky_camera_strings.dart';

class SkyCameraMetricDisplay {
  const SkyCameraMetricDisplay({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
}

enum SkyCameraGpsSignalStrength { none, bad, poor, good }

class SkyCameraTelemetryVisibilityPolicy {
  const SkyCameraTelemetryVisibilityPolicy({
    this.minimumSpeedMetersPerSecond = 5,
    this.showUnavailableData = false,
  });

  const SkyCameraTelemetryVisibilityPolicy.debug()
    : minimumSpeedMetersPerSecond = 5,
      showUnavailableData = true;

  /// Filters stationary GPS noise while retaining taxi and airborne speeds.
  final double minimumSpeedMetersPerSecond;

  /// Intended for explicit component previews only, never selected by build mode.
  final bool showUnavailableData;

  bool hasGpsData(SkyCameraOverlaySnapshot snapshot) {
    final latitude = snapshot.latitude;
    final longitude = snapshot.longitude;
    return snapshot.hasLiveLocation &&
        latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  bool hasAltitudeData(SkyCameraOverlaySnapshot snapshot) {
    final value = snapshot.altitudeMeters;
    return value != null && value.isFinite;
  }

  bool hasSpeedData(SkyCameraOverlaySnapshot snapshot) {
    final value = snapshot.speedMetersPerSecond;
    return value != null &&
        value.isFinite &&
        value >= minimumSpeedMetersPerSecond;
  }

  bool hasTemperatureData(SkyCameraOverlaySnapshot snapshot) {
    final value = snapshot.outsideTemperatureCelsius;
    return value != null && value.isFinite;
  }

  bool shouldShowTechStrip(SkyCameraOverlaySnapshot snapshot) =>
      showUnavailableData || hasGpsData(snapshot);
}

class SkyCameraTelemetryFormatter {
  const SkyCameraTelemetryFormatter({
    required this.snapshot,
    required this.strings,
    this.visibilityPolicy = const SkyCameraTelemetryVisibilityPolicy(),
  });

  final SkyCameraOverlaySnapshot snapshot;
  final SkyCameraStrings strings;
  final SkyCameraTelemetryVisibilityPolicy visibilityPolicy;

  bool get hasGpsData => visibilityPolicy.hasGpsData(snapshot);

  bool get shouldShowTechStrip =>
      visibilityPolicy.shouldShowTechStrip(snapshot);

  List<SkyCameraMetricDisplay> get visibleMetricDisplays {
    final metrics = <SkyCameraMetricDisplay>[];
    if (visibilityPolicy.showUnavailableData ||
        visibilityPolicy.hasTemperatureData(snapshot)) {
      metrics.add(
        SkyCameraMetricDisplay(
          icon: Icons.device_thermostat_rounded,
          iconColor: const Color(0xFFFFC72C),
          value: temperatureLabel,
        ),
      );
    }
    if (visibilityPolicy.showUnavailableData ||
        visibilityPolicy.hasAltitudeData(snapshot)) {
      metrics.add(
        SkyCameraMetricDisplay(
          icon: Icons.swap_vert_rounded,
          iconColor: const Color(0xFFFF7A2F),
          value: altitudeLabel,
        ),
      );
    }
    if (visibilityPolicy.showUnavailableData ||
        visibilityPolicy.hasSpeedData(snapshot)) {
      metrics.add(
        SkyCameraMetricDisplay(
          icon: Icons.speed_rounded,
          iconColor: const Color(0xFF19D3A2),
          value: speedLabel,
        ),
      );
    }
    return metrics;
  }

  String get temperatureLabel =>
      _formatTemperature(snapshot.outsideTemperatureCelsius);

  String get speedLabel =>
      _formatMetersPerSecond(snapshot.speedMetersPerSecond);

  String get altitudeLabel => _formatAltitude(snapshot.altitudeMeters);

  String get headingLabel => _formatHeading(snapshot.headingDegrees);

  String get dateLabel => _formatDate(snapshot.timestamp.toLocal());

  String get coordinatesDirectionalLabel => _formatCoordinatesDirectional(
    latitude: snapshot.latitude,
    longitude: snapshot.longitude,
  );

  SkyCameraGpsSignalStrength get gpsSignalStrength {
    if (!hasGpsData) return SkyCameraGpsSignalStrength.none;
    final accuracy = snapshot.horizontalAccuracyMeters;
    if (accuracy == null || !accuracy.isFinite) {
      return SkyCameraGpsSignalStrength.none;
    }
    if (accuracy <= 15) return SkyCameraGpsSignalStrength.good;
    if (accuracy <= 40) return SkyCameraGpsSignalStrength.poor;
    return SkyCameraGpsSignalStrength.bad;
  }

  String get timestampLabel {
    final value = snapshot.timestamp.toLocal();
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  String get coordinatesLabel {
    final lat = snapshot.latitude;
    final lon = snapshot.longitude;
    if (lat == null || lon == null) {
      return strings.noValuePlaceholder;
    }
    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }

  String _formatMetersPerSecond(double? value) {
    if (value == null || !value.isFinite || value < 0) {
      return strings.noValuePlaceholder;
    }
    return switch (strings.speedUnit) {
      SkyCameraSpeedUnit.kmh => '${(value * 3.6).round()} km/h',
      SkyCameraSpeedUnit.mph => '${(value * 2.23693629).round()} mph',
    };
  }

  String _formatAltitude(double? value) {
    if (value == null || !value.isFinite) {
      return strings.noValuePlaceholder;
    }
    return switch (strings.altitudeUnit) {
      SkyCameraAltitudeUnit.meter => _formatMetricAltitude(value),
      SkyCameraAltitudeUnit.foot => _formatFeetAltitude(value),
    };
  }

  String _formatMetricAltitude(double meters) {
    if (meters.abs() >= 1000) {
      final kilometers = meters / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    }
    final roundedMeters = _roundToNearest(meters, 10);
    if (roundedMeters.abs() >= 1000) {
      final kilometers = roundedMeters / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    }
    return '$roundedMeters m';
  }

  String _formatFeetAltitude(double meters) {
    final roundedFeet = _roundToNearest(meters * 3.28084, 100);
    return '${_formatGroupedInt(roundedFeet)} ft';
  }

  int _roundToNearest(double value, int increment) =>
      (value / increment).round() * increment;

  String _formatGroupedInt(int value) {
    final sign = value < 0 ? '-' : '';
    final digits = value.abs().toString();
    final buffer = StringBuffer(sign);
    for (var i = 0; i < digits.length; i += 1) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _formatHeading(double? value) {
    if (value == null || !value.isFinite || value < 0) {
      return strings.noValuePlaceholder;
    }
    final degrees = value.round().toString().padLeft(3, '0');
    return '$degrees°';
  }

  String _formatTemperature(double? value) {
    if (value == null || !value.isFinite) {
      return strings.noValuePlaceholder;
    }
    final prefix = snapshot.outsideTemperatureIsEstimated ? '~' : '';
    return switch (strings.temperatureUnit) {
      SkyCameraTemperatureUnit.celsius => '$prefix${value.round()}°C',
      SkyCameraTemperatureUnit.fahrenheit =>
        '$prefix${((value * 9 / 5) + 32).round()}°F',
    };
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = _monthAbbreviation(value.month);
    final year = (value.year % 100).toString().padLeft(2, '0');
    return switch (strings.dateDisplayFormat) {
      SkyCameraDateDisplayFormat.monthDayYear => "$month $day '$year",
      SkyCameraDateDisplayFormat.dayMonthYear => "$day $month '$year",
    };
  }

  String _formatCoordinatesDirectional({
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null || longitude == null) {
      return strings.noValuePlaceholder;
    }
    final latDirection = latitude >= 0 ? 'N' : 'S';
    final lonDirection = longitude >= 0 ? 'E' : 'W';
    final lat = latitude.abs().toStringAsFixed(3);
    final lon = longitude.abs().toStringAsFixed(3);
    return '$lat° $latDirection, $lon° $lonDirection';
  }

  String _monthAbbreviation(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[(month - 1).clamp(0, months.length - 1)];
  }
}
