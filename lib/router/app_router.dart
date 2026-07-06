import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/learn_article_content.dart';
import 'package:flymap/ui/screens/create_flight/download_completed/download_completed_args.dart';
import 'package:flymap/ui/screens/create_flight/download_completed/download_completed_screen.dart';
import 'package:flymap/ui/screens/about/about_screen.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/airports_search_screen.dart';
import 'package:flymap/ui/screens/create_flight/flight_number_search/flight_number_search_screen.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_args.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_screen.dart';
import 'package:flymap/ui/screens/create_flight/real_route_airport_search/real_route_airport_search_screen.dart';
import 'package:flymap/ui/screens/create_flight/route_type_selector/route_type_selector_screen.dart';
import 'package:flymap/ui/screens/feedback/feedback_screen.dart';
import 'package:flymap/ui/screens/feedback/feedback_screen_args.dart';
import 'package:flymap/ui/screens/flight/flight_screen.dart';
import 'package:flymap/ui/screens/home/home_screen.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_article_screen.dart';
import 'package:flymap/ui/screens/onboarding/onboarding_screen.dart';
import 'package:flymap/ui/screens/flight_video/flight_video_screen.dart';
import 'package:flymap/ui/screens/share_flight/share_flight_image_screen.dart';
import 'package:flymap/ui/screens/settings/profile/settings_profile_screen.dart';
import 'package:flymap/ui/screens/settings/history/history_screen.dart';
import 'package:flymap/ui/screens/settings/storage/storage_screen.dart';
import 'package:flymap/ui/screens/subscription/subscription_management_screen.dart';
import 'package:flymap/domain/usecase/submit_feedback_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// App router configuration using go_router
class AppRouter {
  static const String homeRoute = '/';
  static const String airportsSearchRoute = '/flight-search';
  static const String routeTypeSelectorRoute = '/route-type-selector';
  static const String flightNumberSearchRoute = '/flight-number-selector';
  static const String realRouteAirportSearchRoute =
      '/real-route-airport-search';
  static const String flightPreviewRoute = '/flight-preview';
  static const String flightRoute = '/flight';
  static const String shareImageRoute = '/share-image';
  static const String flightVideoRoute = '/flight-video';
  static const String downloadCompletedRoute = '/download-completed';
  static const String settingsRoute = '/settings';
  static const String feedbackRoute = '/feedback';
  static const String subscriptionRoute = '/subscription';
  static const String aboutRoute = '/about';
  static const String onboardingRoute = '/onboarding';
  static const String settingsProfileRoute = '/settings/profile';
  static const String settingsStorageRoute = '/settings/storage';
  static const String settingsHistoryRoute = '/settings/history';
  static const String learnArticleRoute = '/learn/article';

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
          path: airportsSearchRoute,
          name: 'airports-search',
          builder: (context, state) => const AirportsSearchScreen(),
        ),

        GoRoute(
          path: flightNumberSearchRoute,
          name: 'flight-number-search',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final hasPendingFlightUnlock =
                extra?['hasPendingFlightUnlock'] as bool? ?? false;
            return FlightNumberSearchScreen(
              hasPendingFlightUnlock: hasPendingFlightUnlock,
            );
          },
        ),

        GoRoute(
          path: realRouteAirportSearchRoute,
          name: 'real-route-airport-search',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final hasPendingFlightUnlock =
                extra?['hasPendingFlightUnlock'] as bool? ?? false;
            return RealRouteAirportSearchScreen(
              hasPendingFlightUnlock: hasPendingFlightUnlock,
            );
          },
        ),

        GoRoute(
          path: routeTypeSelectorRoute,
          name: 'route-type-selector',
          builder: (context, state) => const FlightRouteTypeSelector(),
        ),

        GoRoute(
          path: flightPreviewRoute,
          name: 'flight-preview',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final departure = extra?['departure'] as Airport?;
            final arrival = extra?['arrival'] as Airport?;
            final flightNumber = extra?['flightNumber'] as String?;
            final fr24Id = extra?['fr24Id'] as String?;
            final hasPendingFlightUnlock =
                extra?['hasPendingFlightUnlock'] as bool? ?? false;
            if (departure == null || arrival == null) {
              return const AirportsSearchScreen();
            }
            return FlightPreviewScreen(
              args: FlightPreviewArgs(
                departure: departure,
                arrival: arrival,
                flightNumber: flightNumber,
                fr24Id: fr24Id,
                hasPendingFlightUnlock: hasPendingFlightUnlock,
              ),
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

        // Share Image Screen route
        GoRoute(
          path: shareImageRoute,
          name: 'share-image',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final flightId = extra?['flightId'] as String?;
            if (flightId == null || flightId.isEmpty) {
              return const HomeScreen();
            }

            return ShareFlightImageScreen(flightId: flightId);
          },
        ),

        // Flight Video Screen route
        GoRoute(
          path: flightVideoRoute,
          name: 'flight-video',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final flightId = extra?['flightId'] as String?;
            if (flightId == null || flightId.isEmpty) {
              return const HomeScreen();
            }

            return FlightVideoScreen(flightId: flightId);
          },
        ),

        GoRoute(
          path: downloadCompletedRoute,
          name: 'download-completed',
          builder: (context, state) {
            final args = state.extra as DownloadCompletedArgs?;
            if (args == null || args.flightId.isEmpty) {
              return const HomeScreen();
            }
            return DownloadCompletedRouteScreen(args: args);
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
          path: settingsStorageRoute,
          name: 'settings-storage',
          builder: (context, state) => const StorageScreen(),
        ),
        GoRoute(
          path: settingsHistoryRoute,
          name: 'settings-history',
          builder: (context, state) => const HistoryScreen(),
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

        GoRoute(
          path: learnArticleRoute,
          name: 'learn-article',
          builder: (context, state) {
            final article = state.extra as LearnArticleContent?;
            if (article == null) {
              return const HomeScreen(initialTab: HomeRootTab.learn);
            }
            return LearnArticleScreen(article: article);
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
    context.go(airportsSearchRoute);
  }

  static void goToFlightNumberSelector(
    BuildContext context, {
    bool hasPendingFlightUnlock = false,
  }) {
    context.push(
      flightNumberSearchRoute,
      extra: {'hasPendingFlightUnlock': hasPendingFlightUnlock},
    );
  }

  static void replaceWithFlightNumberSelector(
    BuildContext context, {
    bool hasPendingFlightUnlock = false,
  }) {
    context.pushReplacement(
      flightNumberSearchRoute,
      extra: {'hasPendingFlightUnlock': hasPendingFlightUnlock},
    );
  }

  static void goToRouteTypeSelector(BuildContext context) {
    context.push(routeTypeSelectorRoute);
  }

  static void goToRealRouteAirportSearch(
    BuildContext context, {
    bool hasPendingFlightUnlock = false,
  }) {
    context.push(
      realRouteAirportSearchRoute,
      extra: {'hasPendingFlightUnlock': hasPendingFlightUnlock},
    );
  }

  static void goToRouteTypeSelectorFromOnboarding(BuildContext context) {
    context.go(routeTypeSelectorRoute);
  }

  /// Navigate to flight screen with flight
  static void goToFlight(BuildContext context, {required Flight flight}) {
    context.push(flightRoute, extra: {'flight': flight});
  }

  /// Navigate to flight overview with selected airports
  static void goToFlightOverview(
    BuildContext context, {
    required Airport departure,
    required Airport arrival,
    String? flightNumber,
    String? fr24Id,
    bool hasPendingFlightUnlock = false,
  }) {
    final extra = <String, dynamic>{
      'departure': departure,
      'arrival': arrival,
      'hasPendingFlightUnlock': hasPendingFlightUnlock,
    };
    if (flightNumber != null && flightNumber.trim().isNotEmpty) {
      extra['flightNumber'] = flightNumber;
    }
    if (fr24Id != null && fr24Id.trim().isNotEmpty) {
      extra['fr24Id'] = fr24Id;
    }
    context.push(flightPreviewRoute, extra: extra);
  }

  /// Navigate to share image screen with flight id.
  static void goToShareImage(BuildContext context, {required String flightId}) {
    context.push(shareImageRoute, extra: {'flightId': flightId});
  }

  /// Navigate to flight video screen with flight id.
  static void goToFlightVideo(
    BuildContext context, {
    required String flightId,
  }) {
    context.push(flightVideoRoute, extra: {'flightId': flightId});
  }

  static void goToDownloadCompleted(
    BuildContext context, {
    required String flightId,
    bool isProSubscriber = false,
    bool usedSingleFlightUnlock = false,
  }) {
    context.go(
      downloadCompletedRoute,
      extra: DownloadCompletedArgs(
        flightId: flightId,
        isProSubscriber: isProSubscriber,
        usedSingleFlightUnlock: usedSingleFlightUnlock,
      ),
    );
  }

  /// Navigate to settings
  static void goToSettings(BuildContext context) {
    context.push(settingsRoute);
  }

  static Future<void> goToSettingsProfile(BuildContext context) {
    return context.push(settingsProfileRoute);
  }

  static Future<void> goToSettingsStorage(BuildContext context) {
    return context.push(settingsStorageRoute);
  }

  static Future<void> goToSettingsHistory(BuildContext context) {
    return context.push(settingsHistoryRoute);
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

  static Future<void> goToLearnArticle(
    BuildContext context, {
    required LearnArticleContent article,
  }) {
    return context.push(learnArticleRoute, extra: article);
  }

  /// Navigate to about
  static void goToAbout(BuildContext context) {
    context.push(aboutRoute);
  }
}
