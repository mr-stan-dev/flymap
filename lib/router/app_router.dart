import 'package:flymap/entity/flight.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_screen.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/flight_search_screen.dart';
import 'package:flymap/ui/screens/home/home_screen.dart';
import 'package:flymap/ui/screens/flight/flight_screen.dart';
import 'package:flymap/ui/screens/settings/settings_screen.dart';
import 'package:flymap/ui/screens/about/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App router configuration using go_router
class AppRouter {
  static const String homeRoute = '/';
  static const String flightMapPreviewRoute = '/flightPreview';
  static const String flightSearchRoute = '/flight-number';
  static const String flightRoute = '/flight';
  static const String settingsRoute = '/settings';
  static const String aboutRoute = '/about';

  /// Create the router configuration
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: homeRoute,
      debugLogDiagnostics: true,
      routes: [
        // Home route - HomeScreen
        GoRoute(
          path: homeRoute,
          name: 'flight_search',
          builder: (context, state) => const HomeScreen(),
        ),

        // Flight Number Screen route
        GoRoute(
          path: flightSearchRoute,
          name: 'flight-search',
          builder: (context, state) => const FlightSearchScreen(),
        ),

        // Flight Map Preview route
        GoRoute(
          path: flightMapPreviewRoute,
          name: 'create_flight-map-preview',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final params = extra?['params'] as FlightPreviewParams?;

            switch (params) {
              case null:
                // TODO: Handle this case.
                throw UnimplementedError();
              case FlightPreviewAirports():
                return FlightPreviewScreen(airports: params);
            }
          },
        ),

        // Flight Screen route
        GoRoute(
          path: flightRoute,
          name: 'flight',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final flight = extra?['flight'] as Flight;

            return FlightScreen(flight: flight);
          },
        ),

        // Settings route
        GoRoute(
          path: settingsRoute,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // About
        GoRoute(
          path: aboutRoute,
          name: 'about',
          builder: (context, state) => const AboutScreen(),
        ),
      ],
    );
  }

  /// Navigate to flight_search
  static void goHome(BuildContext context) {
    context.go(homeRoute);
  }

  /// Navigate to create_flight map preview with create_flight
  static void goToFlightPreviewScreen(
    BuildContext context, {
    required FlightPreviewParams params,
  }) {
    context.push(flightMapPreviewRoute, extra: {'params': params});
  }

  /// Navigate to flight screen with flight
  static void goToFlight(BuildContext context, {required Flight flight}) {
    context.push(flightRoute, extra: {'flight': flight});
  }

  /// Navigate to settings
  static void goToSettings(BuildContext context) {
    context.push(settingsRoute);
  }

  /// Navigate to about
  static void goToAbout(BuildContext context) {
    context.push(aboutRoute);
  }
}
