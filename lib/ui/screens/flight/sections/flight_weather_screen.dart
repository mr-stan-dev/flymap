import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_unlock_gate_sheet.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_button.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_forecast_body.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_weather_cubit.dart';
import 'package:flymap/ui/screens/shared/premium/route_premium_gate_interactions.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:get_it/get_it.dart';

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
  /// Set once a one-time unlock is purchased/consumed this session. The saved
  /// flight's persisted tier is also flipped to Pro (so the unlock sticks on
  /// reopen), but [widget.flight] is a stale snapshot, so this local flag makes
  /// the current screen treat the flight as Pro immediately.
  bool _unlocked = false;

  /// A date picked in-session for a dateless flight. Overrides the stale
  /// [widget.flight] snapshot until the flight reloads with the persisted one.
  FlightSchedule? _pickedSchedule;

  FlightSchedule? get _schedule => _pickedSchedule ?? widget.flight.schedule;

  bool get _hasProAccess =>
      widget.flight.hasProAccess ||
      _unlocked ||
      context.read<SubscriptionCubit>().state.isPro;

  /// The free teaser's upgrade path. Shows the one-time-unlock bottom sheet
  /// first (unlock this flight, or view Pro plans) instead of jumping straight
  /// to the paywall. Guarded by a connectivity check — a saved flight is often
  /// opened in airplane mode, and both the purchase and the paywall need the
  /// network, so we explain rather than fail.
  Future<void> _openUpgradeGate() async {
    final subscriptionCubit = context.read<SubscriptionCubit>();
    if (subscriptionCubit.state.isPro) return;

    final hasInternet = await const ConnectivityChecker()
        .hasInternetConnectivity();
    if (!mounted) return;
    if (!hasInternet) {
      await RoutePremiumGateInteractions.showOfflineInfoSheet(context);
      return;
    }

    final route = widget.flight.route;
    await showFlightUnlockGateSheet(
      context: context,
      subscriptionCubit: subscriptionCubit,
      source: PaywallSource.routeTimelineGate,
      routePreview:
          '${route.departure.displayCode} → ${route.arrival.displayCode}',
      presentProPaywall: () => subscriptionCubit.presentPaywallForSource(
        source: PaywallSource.routeTimelineGate,
      ),
      // One-time unlock: persist this flight as Pro so it stays unlocked, then
      // fetch the forecast in place.
      onUnlockActivated: _onFlightUnlocked,
      // Subscription unlocks every flight (isPro flips app-wide); just fetch.
      onProActivated: () => _fetchForecast(),
    );
  }

  Future<void> _onFlightUnlocked() async {
    if (GetIt.I.isRegistered<FlightRepository>()) {
      await GetIt.I.get<FlightRepository>().updateFlightAccessTier(
        flightId: widget.flight.id,
        accessTier: Flight.accessTierPro,
      );
    }
    if (!mounted) return;
    setState(() => _unlocked = true);
    await _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    if (!mounted) return;
    await context.read<FlightWeatherCubit>().fetchIfNeeded(
      hasProAccess: true,
      force: true,
    );
  }

  /// Dateless approximate flight: pick a day, persist it on the flight, and
  /// fetch. (Real flights don't get this — [onPickDate] is null for them.)
  Future<void> _handlePickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    final schedule = FlightSchedule.dateOnly(
      DateTime(picked.year, picked.month, picked.day),
    );
    if (GetIt.I.isRegistered<FlightRepository>()) {
      await GetIt.I.get<FlightRepository>().updateFlightSchedule(
        flightId: widget.flight.id,
        schedule: schedule,
      );
    }
    if (!mounted) return;
    setState(() => _pickedSchedule = schedule);
    await context.read<FlightWeatherCubit>().applySchedule(
      schedule,
      hasProAccess: _hasProAccess,
    );
  }

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
        _unlocked ||
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
                      // Saved flight: share pulls the map base from the
                      // offline cache so airplane-mode shares keep the map.
                      flightId: flight.id,
                    );
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: WeatherForecastBody(
                    route: flight.route,
                    schedule: _schedule,
                    weather: weather,
                    isLoading: state.isLoading,
                    isProUser: isProUser,
                    // Saved flight: the card's satellite base comes from the
                    // per-flight offline cache so it shows in airplane mode.
                    flightId: flight.id,
                    // On a saved flight a failure means nothing was downloaded
                    // before takeoff — say that instead of a generic error.
                    failedCopy: context.t.createFlight.weather.notDownloadedBody,
                    onRetry: () => unawaited(
                      context.read<FlightWeatherCubit>().fetchIfNeeded(
                        hasProAccess: _hasProAccess,
                        force: true,
                      ),
                    ),
                    onPremiumGateTap: () => unawaited(_openUpgradeGate()),
                    // Pull-to-refresh forces a fresh fetch, bypassing the 6h
                    // cache that governs the automatic on-open refresh.
                    onRefresh: isProUser
                        ? () => context.read<FlightWeatherCubit>().fetchIfNeeded(
                            hasProAccess: true,
                            force: true,
                          )
                        : null,
                    // Approximate flights can add a date inline; real flights
                    // must be re-selected with a date, so no picker for them.
                    onPickDate:
                        (flight.operationalData?.flightNumber ?? '')
                            .trim()
                            .isNotEmpty
                        ? null
                        : () => unawaited(_handlePickDate()),
                  ),
                ),
                // The teaser itself is non-interactive; the free flow needs a
                // real upgrade action, which the shared body leaves to the
                // host. (No "continue without weather" here — this is a saved
                // flight, not a step in the creation flow.)
                if (!isProUser)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: PremiumButton(
                        label: context.t.common.upgrade,
                        icon: Icons.workspace_premium_rounded,
                        onPressed: () => unawaited(_openUpgradeGate()),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
