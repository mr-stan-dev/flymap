import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/map_download_config.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/flight/sections/flight_weather_screen.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_weather_cubit.dart';
import 'package:flymap/ui/screens/flight/widgets/flight_app_bar.dart';
import 'package:flymap/ui/screens/flight/widgets/gps_signal_help_sheet.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/dashboard_tab_view.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/hub/flight_hub_tab_view.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_tab.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_screen.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:get_it/get_it.dart';

class FlightScreen extends StatelessWidget {
  final Flight flight;
  final FlightScreenCubit? cubit;

  /// True when opened from a forecast notification: lands directly on the
  /// weather section.
  final bool openWeather;

  const FlightScreen({
    super.key,
    required this.flight,
    this.cubit,
    this.openWeather = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = BlocProvider(
      create: (_) => FlightWeatherCubit(flight: flight),
      child: _FlightScreenView(openWeather: openWeather),
    );
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: child);
    }
    return BlocProvider(
      create: (context) => FlightScreenCubit(flight: flight),
      child: child,
    );
  }
}

class _FlightScreenView extends StatefulWidget {
  const _FlightScreenView({this.openWeather = false});

  final bool openWeather;

  @override
  State<_FlightScreenView> createState() => _FlightScreenViewState();
}

class _FlightScreenViewState extends State<_FlightScreenView> {
  static const int _hubTabIndex = 2;
  static const int _cameraTabIndex = 3;

  int _tabIndex = 0;
  bool _isGpsHelpSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _logFlightOpened();
    if (widget.openWeather) {
      // Forecast notification tap: land on the hub with the weather
      // section already open.
      _tabIndex = _hubTabIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openWeatherScreen());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.72),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
        currentIndex: _tabIndex,
        onTap: _handleNavigationTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            activeIcon: const Icon(Icons.map),
            label: t.flight.tabMap,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.speed_outlined),
            activeIcon: const Icon(Icons.speed),
            label: t.flight.tabDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline_rounded),
            activeIcon: const Icon(Icons.info_rounded),
            label: t.flight.tabInfo,
          ),
          BottomNavigationBarItem(
            icon: const Icon(
              Icons.camera_alt_outlined,
              key: Key('flight.camera_action'),
            ),
            activeIcon: const Icon(Icons.camera_alt),
            label: t.flight.tabCamera,
          ),
        ],
      ),
      body: BlocConsumer<FlightScreenCubit, FlightScreenState>(
        listener: (context, state) {
          if (state is FlightScreenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          if (state is FlightScreenDeleted) {
            homeRefreshNotifier.value = true;
            AppRouter.goHome(context);
          }
        },
        builder: (context, state) {
          final flight = _extractFlight(state);

          return Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    FlightMapTabView(
                      topPadding: _tabTopPadding(context),
                      onGpsHelpTap: _openGpsSignalHelpSheet,
                    ),
                    FlightDashboardTabView(
                      state: state,
                      topPadding: _tabTopPadding(context),
                      onGpsHelpTap: _openGpsSignalHelpSheet,
                    ),
                    FlightHubTabView(topPadding: _tabTopPadding(context)),
                  ],
                ),
              ),
              if (flight != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: FlightAppBar(flight: flight),
                ),
            ],
          );
        },
      ),
    );
  }

  Flight? _extractFlight(FlightScreenState state) {
    if (state is FlightScreenLoaded) {
      return state.flight;
    }
    if (state is FlightScreenError) {
      return state.flight;
    }
    return null;
  }

  double _tabTopPadding(BuildContext context) {
    return FlightAppBar.totalOverlayHeight(context) + 8;
  }

  Future<void> _openGpsSignalHelpSheet() async {
    if (!mounted || _isGpsHelpSheetOpen) {
      return;
    }
    _isGpsHelpSheetOpen = true;
    try {
      await showGpsSignalHelpSheet(context);
    } finally {
      _isGpsHelpSheetOpen = false;
    }
  }

  void _handleNavigationTap(int index) {
    if (index == _cameraTabIndex) {
      unawaited(_openCamera());
      return;
    }
    setState(() => _tabIndex = index);
  }

  Future<void> _openWeatherScreen() async {
    final flightCubit = context.read<FlightScreenCubit>();
    final weatherCubit = context.read<FlightWeatherCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: flightCubit),
            BlocProvider.value(value: weatherCubit),
          ],
          child: FlightWeatherScreen(flight: weatherCubit.flight),
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    final flightId = context.read<FlightScreenCubit>().flight.id;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlymapSkyCameraScreen.forFlight(flightId: flightId),
        fullscreenDialog: true,
      ),
    );
  }

  void _logFlightOpened() {
    if (!GetIt.I.isRegistered<AppAnalytics>()) return;
    final flight = context.read<FlightScreenCubit>().flight;
    unawaited(
      GetIt.I.get<AppAnalytics>().log(
        FlightOpenedEvent(
          routeSource: flight.route.source,
          routeLength: MapDownloadConfig.resolveRouteLength(
            flight.route.distanceInKm,
          ),
          accessTier: _resolveAccessTier(flight),
        ),
      ),
    );
  }

  FlightOpenedAccessTier _resolveAccessTier(Flight flight) {
    if (!flight.hasProAccess) return FlightOpenedAccessTier.free;
    try {
      return context.read<SubscriptionCubit>().state.isPro
          ? FlightOpenedAccessTier.pro
          : FlightOpenedAccessTier.flightUnlock;
    } catch (_) {
      return FlightOpenedAccessTier.pro;
    }
  }
}
