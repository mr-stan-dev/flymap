import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_forecast_body.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';

/// Dedicated weather step: route overview -> WEATHER -> Wikipedia articles.
/// The forecast experience itself is [WeatherForecastBody] (shared with the
/// flight screen); this step adds the create-flight chrome: Continue for
/// Pro, the upgrade + continue-without pair for free.
class FlightSearchWeatherStep extends StatelessWidget {
  const FlightSearchWeatherStep({
    required this.state,
    required this.isProUser,
    required this.onRetry,
    required this.onContinue,
    required this.onPremiumGateTap,
    this.onPickDate,
    this.onGoBack,
    super.key,
  });

  final FlightPreviewState state;
  final bool isProUser;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final VoidCallback onPremiumGateTap;
  final VoidCallback? onPickDate;
  final VoidCallback? onGoBack;

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final isBeyondHorizon = WeatherForecastBody.isBeyondHorizon(
      isProUser: isProUser,
      weather: state.flightWeather,
      schedule: state.flightSchedule,
    );

    return Column(
      children: [
        Expanded(
          child: WeatherForecastBody(
            route: state.flightRoute,
            schedule: state.flightSchedule,
            weather: state.flightWeather,
            isLoading: state.isWeatherLoading,
            isProUser: isProUser,
            onRetry: onRetry,
            onPremiumGateTap: onPremiumGateTap,
            onPickDate: onPickDate,
            onGoBack: onGoBack,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          // Free flights get the paywall anatomy: upgrade is THE primary
          // action, with a quiet way past it right below.
          child: isProUser
              ? SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: isBeyondHorizon
                        ? t.continueWithoutWeather
                        : context.t.common.kContinue,
                    onPressed: onContinue,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumButton(
                      label: context.t.common.upgrade,
                      icon: Icons.workspace_premium_rounded,
                      onPressed: onPremiumGateTap,
                    ),
                    const SizedBox(height: 4),
                    TertiaryButton(
                      label: t.continueWithoutWeather,
                      onPressed: onContinue,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
