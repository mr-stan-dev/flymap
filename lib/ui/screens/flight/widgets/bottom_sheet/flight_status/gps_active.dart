import 'package:flymap/ui/theme/app_colours.dart';
import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/entity/gps_data.dart';

class GpsActive extends StatelessWidget {
  final FlightScreenLoaded state;

  const GpsActive({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Speed indicator
            Expanded(child: _buildSpeedIndicator(context)),
            const SizedBox(width: 12),
            // Altitude indicator
            Expanded(child: _buildAltitudeIndicator(context)),
          ],
        ),
        const SizedBox(height: 16),

        // Compass and GPS Accuracy
        Row(
          children: [
            // Compass
            Expanded(child: _buildCompass(context)),
            const SizedBox(width: 12),
            // GPS Accuracy
            Expanded(child: _buildGpsAccuracyIndicator(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedIndicator(BuildContext context) {
    final speed = state.gpsData?.speed ?? const SpeedValue(0, 'km/h');

    return DashboardCard(
      icon: Icons.speed,
      iconColor: AppColoursCommon.accentBlue,
      title: 'SPEED',
      mainValue: speed.value.toStringAsFixed(0),
      mainValueColor: AppColoursCommon.accentBlue,
      subtitle: speed.unit,
    );
  }

  Widget _buildAltitudeIndicator(BuildContext context) {
    final altitude = state.gpsData?.altitude ?? const AltitudeValue(0, 'ft');

    return DashboardCard(
      icon: Icons.height,
      iconColor: Colors.purple,
      title: 'ALTITUDE',
      mainValue: altitude.value.toStringAsFixed(0),
      mainValueColor: Colors.purple,
      subtitle: altitude.unit,
    );
  }

  Widget _buildCompass(BuildContext context) {
    final course = state.gpsData?.course ?? 0.0;

    // Convert course angle to cardinal direction
    String getCardinalDirection(double angle) {
      // Normalize angle to 0-360 range
      double normalizedAngle = angle % 360;
      if (normalizedAngle < 0) normalizedAngle += 360;

      // Define cardinal directions with their angle ranges
      if (normalizedAngle >= 337.5 || normalizedAngle < 22.5) return 'N';
      if (normalizedAngle >= 22.5 && normalizedAngle < 67.5) return 'NE';
      if (normalizedAngle >= 67.5 && normalizedAngle < 112.5) return 'E';
      if (normalizedAngle >= 112.5 && normalizedAngle < 157.5) return 'SE';
      if (normalizedAngle >= 157.5 && normalizedAngle < 202.5) return 'S';
      if (normalizedAngle >= 202.5 && normalizedAngle < 247.5) return 'SW';
      if (normalizedAngle >= 247.5 && normalizedAngle < 292.5) return 'W';
      if (normalizedAngle >= 292.5 && normalizedAngle < 337.5) return 'NW';

      return 'N'; // Default fallback
    }

    return DashboardCard(
      icon: Icons.compass_calibration,
      iconColor: Colors.orange,
      title: 'COURSE',
      mainValue: getCardinalDirection(course),
      mainValueColor: Colors.orange,
      subtitle: '${course.toStringAsFixed(0)}°',
    );
  }

  Widget _buildGpsAccuracyIndicator(BuildContext context) {
    final accuracy = state.gpsData?.accuracy;

    if (accuracy == null) {
      return DashboardCard(
        icon: Icons.gps_fixed,
        iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        title: 'GPS ACCURACY',
        mainValue: 'N/A',
        mainValueColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
      );
    }

    Color accuracyColor;
    String accuracyText;

    if (accuracy < 10) {
      accuracyColor = Colors.green;
      accuracyText = 'Excellent';
    } else if (accuracy < 25) {
      accuracyColor = Colors.orange;
      accuracyText = 'Good';
    } else {
      accuracyColor = Colors.red;
      accuracyText = 'Poor';
    }

    return DashboardCard(
      icon: Icons.gps_fixed,
      iconColor: accuracyColor,
      title: 'GPS ACCURACY',
      mainValue: accuracyText,
      mainValueColor: accuracyColor,
      subtitle: '±${accuracy.toStringAsFixed(0)}m',
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String mainValue;
  final Color mainValueColor;
  final String? subtitle;
  final Widget? customWidget;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.mainValue,
    required this.mainValueColor,
    this.subtitle,
    this.customWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          if (customWidget != null) ...[
            customWidget!,
            const SizedBox(height: 4),
          ],
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: mainValueColor,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(fontSize: 10, color: onSurface.withOpacity(0.7)),
            ),
        ],
      ),
    );
  }
}
