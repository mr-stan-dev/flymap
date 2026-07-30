import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_button.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_forecast_body.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_weather_cubit.dart';
import 'package:flymap/ui/screens/shared/premium/route_premium_gate_interactions.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';

/// The saved flight's forecast — the same [WeatherForecastBody] experience
/// as the create-flight weather step (Pro forecast / free teaser /
/// beyond-horizon explainer), fed by the shared [FlightWeatherCubit].
class FlightWeatherScreen extends StatefulWidget {
  const FlightWeatherScreen({required this.flight, super.key});

  final Flight flight;

  @override
  State<FlightWeatherScreen> createState() => _FlightWeatherScreenState();
}

class _FlightWeatherScreenState extends State<FlightWeatherScreen> {
  bool get _hasProAccess =>
      widget.flight.hasProAccess ||
      context.read<SubscriptionCubit>().state.isPro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<FlightWeatherCubit>().fetchIfNeeded(
          hasProAccess: _hasProAccess,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final isProUser =
        flight.hasProAccess ||
        context.select((SubscriptionCubit cubit) => cubit.state.isPro);

    return BlocBuilder<FlightWeatherCubit, FlightWeatherState>(
      builder: (context, state) {
        final weather = state.weather;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.t.createFlight.steps.weatherTitle),
            actions: [
              if (isProUser && weather != null && weather.samples.isNotEmpty)
                Builder(
                  builder: (context) {
                    final verdict = FlightWeatherVerdictPolicy.overallVerdict(
                      weather.samples,
                    );
                    final (emoji, title, _) = verdictPresentation(
                      verdict,
                      context.t.createFlight.weather,
                    );
                    return WeatherShareButton(
                      route: flight.route,
                      weather: weather,
                      verdictEmoji: emoji,
                      verdictTitle: title,
                      flightNumber: flight.operationalData?.flightNumber,
                    );
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: WeatherForecastBody(
              route: flight.route,
              schedule: flight.schedule,
              weather: weather,
              isLoading: state.isLoading,
              isProUser: isProUser,
              onRetry: () => unawaited(
                context.read<FlightWeatherCubit>().fetchIfNeeded(
                  hasProAccess: _hasProAccess,
                  force: true,
                ),
              ),
              onPremiumGateTap: () => unawaited(
                RoutePremiumGateInteractions.onGateTap(
                  context: context,
                  source: PaywallSource.routeTimelineGate,
                  useOfflineInfoSheet: true,
                  onActivated: () async {
                    if (!mounted) return;
                    await context.read<FlightWeatherCubit>().fetchIfNeeded(
                      hasProAccess: true,
                      force: true,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
