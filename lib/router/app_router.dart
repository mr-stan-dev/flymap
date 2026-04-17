import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/ui/screens/about/about_screen.dart';
import 'package:flymap/ui/screens/create_flight/airport_selection/airport_selection_screen.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_args.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_screen.dart';
import 'package:flymap/ui/screens/feedback/feedback_screen.dart';
import 'package:flymap/ui/screens/feedback/feedback_screen_args.dart';
import 'package:flymap/ui/screens/flight/flight_screen.dart';
import 'package:flymap/ui/screens/home/home_screen.dart';
import 'package:flymap/ui/screens/onboarding/onboarding_screen.dart';
import 'package:flymap/ui/screens/share_flight/share_flight_screen.dart';
import 'package:flymap/ui/screens/settings/profile/settings_profile_screen.dart';
import 'package:flymap/ui/screens/subscription/subscription_management_screen.dart';
import 'package:flymap/usecase/submit_feedback_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// App router configuration using go_router
class AppRouter {
  static const String homeRoute = '/';
  static const String flightSearchRoute = '/flight-search';
  static const String flightPreviewRoute = '/flight-preview';
  static const String flightRoute = '/flight';
  static const String shareFlightRoute = '/share-flight';
  static const String settingsRoute = '/settings';
  static const String feedbackRoute = '/feedback';
  static const String subscriptionRoute = '/subscription';
  static const String aboutRoute = '/about';
  static const String onboardingRoute = '/onboarding';
  static const String settingsProfileRoute = '/settings/profile';

  /// Create the router configuration
  static GoRouter createRouter({required bool showOnboarding}) {
    return GoRouter(
      initialLocation: showOnboarding ? onboardingRoute : homeRoute,
      debugLogDiagnostics: true,
      observers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      routes: [
        // Home route - HomeScreen
        GoRoute(
          path: homeRoute,
          name: 'flight_search',
          builder: (context, state) => const HomeScreen(),
        ),

        GoRoute(
          path: onboardingRoute,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // Flight Search screen route
        GoRoute(
          path: flightSearchRoute,
          name: 'flight-search',
          builder: (context, state) => const AirportSelectionScreen(),
        ),

        GoRoute(
          path: flightPreviewRoute,
          name: 'flight-preview',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final departure = extra?['departure'] as Airport?;
            final arrival = extra?['arrival'] as Airport?;
            if (departure == null || arrival == null) {
              return const AirportSelectionScreen();
            }
            return FlightPreviewScreen(
              args: FlightPreviewArgs(departure: departure, arrival: arrival),
            );
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

        // Share Flight Screen route
        GoRoute(
          path: shareFlightRoute,
          name: 'share-flight',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final flight = extra?['flight'] as Flight;

            return ShareFlightScreen(flight: flight);
          },
        ),

        // Settings route
        GoRoute(
          path: settingsRoute,
          name: 'settings',
          builder: (context, state) =>
              const HomeScreen(initialTab: HomeRootTab.settings),
        ),

        GoRoute(
          path: settingsProfileRoute,
          name: 'settings-profile',
          builder: (context, state) => const SettingsProfileScreen(),
        ),

        GoRoute(
          path: feedbackRoute,
          name: 'feedback',
          builder: (context, state) {
            final args =
                state.extra as FeedbackScreenArgs? ??
                const FeedbackScreenArgs(source: 'unknown', isPro: false);
            return FeedbackScreen(
              args: args,
              submitFeedbackUseCase: GetIt.I.get<SubmitFeedbackUseCase>(),
            );
          },
        ),

        // Subscription management route
        GoRoute(
          path: subscriptionRoute,
          name: 'subscription',
          builder: (context, state) => const SubscriptionManagementScreen(),
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

  static void goToFlightSearch(BuildContext context) {
    context.go(flightSearchRoute);
  }

  /// Navigate to flight screen with flight
  static void goToFlight(BuildContext context, {required Flight flight}) {
    context.push(flightRoute, extra: {'flight': flight});
  }

  /// Navigate to flight preview with selected airports
  static void goToFlightPreview(
    BuildContext context, {
    required Airport departure,
    required Airport arrival,
  }) {
    context.push(
      flightPreviewRoute,
      extra: {'departure': departure, 'arrival': arrival},
    );
  }

  /// Navigate to share flight screen with flight
  static void goToShareFlight(BuildContext context, {required Flight flight}) {
    context.push(shareFlightRoute, extra: {'flight': flight});
  }

  /// Navigate to settings
  static void goToSettings(BuildContext context) {
    context.push(settingsRoute);
  }

  static Future<void> goToSettingsProfile(BuildContext context) {
    return context.push(settingsProfileRoute);
  }

  /// Navigate to feedback and return true when submitted.
  static Future<bool> goToFeedback(
    BuildContext context, {
    required String source,
    required bool isPro,
  }) async {
    final result = await context.push<bool>(
      feedbackRoute,
      extra: FeedbackScreenArgs(source: source, isPro: isPro),
    );
    return result ?? false;
  }

  /// Navigate to subscription management
  static void goToSubscriptionManagement(BuildContext context) {
    context.push(subscriptionRoute);
  }

  /// Navigate to about
  static void goToAbout(BuildContext context) {
    context.push(aboutRoute);
  }
}
