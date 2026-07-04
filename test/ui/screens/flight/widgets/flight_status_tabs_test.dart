import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/gps_data_provider.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_article.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_offline_content.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_insights.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/domain/usecase/complete_flight_use_case.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:flymap/domain/usecase/start_flight_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/flight_unlock_product.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/gps_signal_help_sheet.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/dashboard_panel.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/dashboard_tab_view.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/gps_live_status_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/geo_card/geo_awareness_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_gps_status_badge.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/widgets/map_bottom_status_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/route/flight_route_tab_view.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('map bottom card shows check-in card for upcoming', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        child: MapBottomStatusCard(
          status: FlightStatus.upcoming,
          onSelectedRegionChanged: (_) {},
          onCheckInPressed: () {},
        ),
      ),
    );

    expect(find.text('Begin your flight journey'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('map bottom card uses geo-awareness card for in-progress', (
    tester,
  ) async {
    final cubit = FlightScreenCubit(
      flight: _buildFlight(status: FlightStatus.inProgress),
      deleteFlightUseCase: _NoopDeleteFlightUseCase(),
      completeFlightUseCase: _NoopCompleteFlightUseCase(),
      startFlightUseCase: _FakeStartFlightUseCase(result: true),
      gpsProvider: _FakeGpsDataProvider(),
      enableGpsCheckTimer: false,
    );

    await tester.pumpWidget(
      _testApp(
        child: BlocProvider.value(
          value: cubit,
          child: MapBottomStatusCard(
            status: FlightStatus.inProgress,
            onSelectedRegionChanged: (_) {},
            onCheckInPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(GeoAwarenessCard), findsOneWidget);
    await cubit.close();
    await tester.pump();
  });

  testWidgets(
    'geo-awareness card shows ETA on next region chip only with speed',
    (tester) async {
      final gpsProvider = _FakeGpsDataProvider();
      final subscriptionCubit = _buildSubscriptionCubit();
      addTearDown(subscriptionCubit.close);
      final route = _linearTestRoute();
      final currentDistanceKm = _coveredDistanceKmForTest(
        route,
        const GpsData(
          latitude: 0,
          longitude: 3,
          speed: SpeedValue(600, 'km/h'),
        ),
      );
      final flight = _buildFlight(
        status: FlightStatus.inProgress,
        route: route,
        routeInsights: FlightRouteInsights(
          regions: [
            _buildRegion(
              pathFirstEncounterKm: currentDistanceKm + 200,
              name: 'English Channel',
            ),
          ],
        ),
      );
      final cubit = FlightScreenCubit(
        flight: flight,
        deleteFlightUseCase: _NoopDeleteFlightUseCase(),
        completeFlightUseCase: _NoopCompleteFlightUseCase(),
        startFlightUseCase: _FakeStartFlightUseCase(result: true),
        gpsProvider: gpsProvider,
        enableGpsCheckTimer: false,
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        _testApp(
          child: BlocProvider.value(
            value: subscriptionCubit,
            child: BlocProvider.value(
              value: cubit,
              child: MapBottomStatusCard(
                status: FlightStatus.inProgress,
                onSelectedRegionChanged: (_) {},
                onCheckInPressed: () {},
              ),
            ),
          ),
        ),
      );

      gpsProvider.emit(
        GpsStatus.gpsActive,
        data: const GpsData(
          latitude: 0,
          longitude: 3,
          speed: SpeedValue(600, 'km/h'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('English Channel (in '), findsOneWidget);

      gpsProvider.emit(
        GpsStatus.gpsActive,
        data: const GpsData(latitude: 0, longitude: 3),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect((cubit.state as FlightScreenLoaded).nextRegionEtaMinutes, isNull);
      expect(find.textContaining('English Channel'), findsOneWidget);
      expect(find.textContaining('English Channel (in '), findsNothing);
    },
  );

  testWidgets(
    'geo-awareness card hides region content when GPS is off or unavailable by permission',
    (tester) async {
      final gpsProvider = _FakeGpsDataProvider();
      final subscriptionCubit = _buildSubscriptionCubit();
      addTearDown(subscriptionCubit.close);
      final route = _linearTestRoute();
      final flight = _buildFlight(
        status: FlightStatus.inProgress,
        route: route,
        routeInsights: FlightRouteInsights(
          regions: [
            _buildRegion(
              pathFirstEncounterKm: 200,
              name: 'English Channel',
              geometry: _polygon(1.0, 2.0),
            ),
          ],
        ),
      );
      final cubit = FlightScreenCubit(
        flight: flight,
        deleteFlightUseCase: _NoopDeleteFlightUseCase(),
        completeFlightUseCase: _NoopCompleteFlightUseCase(),
        startFlightUseCase: _FakeStartFlightUseCase(result: true),
        gpsProvider: gpsProvider,
        enableGpsCheckTimer: false,
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        _testApp(
          child: BlocProvider.value(
            value: subscriptionCubit,
            child: BlocProvider.value(
              value: cubit,
              child: MapBottomStatusCard(
                status: FlightStatus.inProgress,
                onSelectedRegionChanged: (_) {},
                onCheckInPressed: () {},
              ),
            ),
          ),
        ),
      );

      gpsProvider.emit(
        GpsStatus.gpsActive,
        data: const GpsData(
          latitude: 0,
          longitude: 1.5,
          speed: SpeedValue(600, 'km/h'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('You are flying over:'), findsOneWidget);
      expect(find.text('English Channel'), findsOneWidget);

      gpsProvider.emit(GpsStatus.off);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('You are flying over:'), findsNothing);
      expect(find.text('English Channel'), findsNothing);

      gpsProvider.emit(GpsStatus.permissionsNotGranted);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('You are flying over:'), findsNothing);
      expect(find.text('English Channel'), findsNothing);
    },
  );

  testWidgets(
    'geo-awareness region sheet shows read more for offline article',
    (tester) async {
      final gpsProvider = _FakeGpsDataProvider();
      final subscriptionCubit = _buildSubscriptionCubit();
      addTearDown(subscriptionCubit.close);
      final route = _linearTestRoute();
      final flight = _buildFlight(
        status: FlightStatus.inProgress,
        route: route,
        routeInsights: FlightRouteInsights(
          regions: [
            _buildRegion(
              qid: 'region-article',
              pathFirstEncounterKm: 200,
              name: 'English Channel',
              geometry: _polygon(1.0, 2.0),
            ),
          ],
        ),
        offlineContent: FlightOfflineContent(
          articles: [
            _buildArticle(qid: 'region-article', title: 'English Channel'),
          ],
        ),
      );
      final cubit = FlightScreenCubit(
        flight: flight,
        deleteFlightUseCase: _NoopDeleteFlightUseCase(),
        completeFlightUseCase: _NoopCompleteFlightUseCase(),
        startFlightUseCase: _FakeStartFlightUseCase(result: true),
        gpsProvider: gpsProvider,
        enableGpsCheckTimer: false,
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        _testApp(
          child: BlocProvider.value(
            value: subscriptionCubit,
            child: BlocProvider.value(
              value: cubit,
              child: MapBottomStatusCard(
                status: FlightStatus.inProgress,
                onSelectedRegionChanged: (_) {},
                onCheckInPressed: () {},
              ),
            ),
          ),
        ),
      );

      gpsProvider.emit(
        GpsStatus.gpsActive,
        data: const GpsData(
          latitude: 0,
          longitude: 1.5,
          speed: SpeedValue(600, 'km/h'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('English Channel').first);
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);
    },
  );

  testWidgets(
    'geo-awareness card updates arrival fallback label near landing at zero speed',
    (tester) async {
      final gpsProvider = _FakeGpsDataProvider();
      final subscriptionCubit = _buildSubscriptionCubit();
      addTearDown(subscriptionCubit.close);
      final route = _linearTestRoute();
      final flight = _buildFlight(
        status: FlightStatus.inProgress,
        route: route,
        routeInsights: FlightRouteInsights(
          regions: [
            _buildRegion(
              qid: 'region-channel',
              pathFirstEncounterKm: 200,
              name: 'English Channel',
              geometry: _polygon(1.0, 2.0),
            ),
            _buildRegion(
              qid: 'region-arrival-area',
              pathFirstEncounterKm: 900,
              name: 'Arrival Area',
              geometry: _polygon(9.6, 10.0),
            ),
          ],
        ),
      );
      final cubit = FlightScreenCubit(
        flight: flight,
        deleteFlightUseCase: _NoopDeleteFlightUseCase(),
        completeFlightUseCase: _NoopCompleteFlightUseCase(),
        startFlightUseCase: _FakeStartFlightUseCase(result: true),
        gpsProvider: gpsProvider,
        enableGpsCheckTimer: false,
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        _testApp(
          child: BlocProvider.value(
            value: subscriptionCubit,
            child: BlocProvider.value(
              value: cubit,
              child: MapBottomStatusCard(
                status: FlightStatus.inProgress,
                onSelectedRegionChanged: (_) {},
                onCheckInPressed: () {},
              ),
            ),
          ),
        ),
      );

      gpsProvider.emit(
        GpsStatus.gpsActive,
        data: const GpsData(
          latitude: 0,
          longitude: 9.5,
          speed: SpeedValue(600, 'km/h'),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Next:'), findsOneWidget);
      expect(find.text('Arriving:'), findsNothing);
      expect(find.text('Arrived:'), findsNothing);
      expect(find.text('Arrival'), findsOneWidget);
      expect(find.textContaining('Arrival (in '), findsNothing);

      gpsProvider.emit(
        GpsStatus.gpsActive,
        data: const GpsData(
          latitude: 0,
          longitude: 9.7,
          speed: SpeedValue(600, 'km/h'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Next:'), findsNothing);
      expect(find.text('Arriving:'), findsOneWidget);
      expect(find.text('Arrived:'), findsNothing);
      expect(find.text('Now:'), findsNothing);
      expect(find.text('Arrival Area'), findsNothing);

      gpsProvider.emit(
        GpsStatus.gpsActive,
        data: const GpsData(
          latitude: 0,
          longitude: 9.95,
          speed: SpeedValue(0, 'km/h'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Arriving:'), findsNothing);
      expect(find.text('Arrived:'), findsOneWidget);
      expect(find.text('Now:'), findsNothing);
      expect(find.text('Arrival Area'), findsNothing);
    },
  );

  testWidgets('dashboard tab shows bottom check-in card for upcoming', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        child: FlightDashboardTabView(
          state: _loadedState(status: FlightStatus.upcoming),
          topPadding: 0,
        ),
      ),
    );

    expect(find.text('Begin your flight journey'), findsNothing);
    expect(find.byType(FlightDashboardPanel), findsOneWidget);
  });

  testWidgets('dashboard tab keeps telemetry layout for in-progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        child: FlightDashboardTabView(
          state: _loadedState(status: FlightStatus.inProgress),
          topPadding: 0,
        ),
      ),
    );

    expect(find.byType(FlightDashboardPanel), findsOneWidget);
  });

  testWidgets('route tab upcoming hides route progress and shows facts strip', (
    tester,
  ) async {
    final subscriptionCubit = _buildSubscriptionCubit();
    addTearDown(subscriptionCubit.close);

    await tester.pumpWidget(
      _testApp(
        child: BlocProvider.value(
          value: subscriptionCubit,
          child: FlightRouteTabView(
            state: _loadedState(status: FlightStatus.upcoming),
            topPadding: 0,
          ),
        ),
      ),
    );

    expect(find.text('Route progress'), findsNothing);
    expect(find.text('LHR → MUC'), findsOneWidget);
    expect(find.text('2h 40m'), findsOneWidget);
  });

  testWidgets('route tab upcoming keeps historical duration consistent', (
    tester,
  ) async {
    final subscriptionCubit = _buildSubscriptionCubit();
    addTearDown(subscriptionCubit.close);

    const departure = Airport(
      name: 'Abu Dhabi International Airport',
      city: 'Abu Dhabi',
      countryCode: 'AE',
      latLon: LatLng(24.4330, 54.6511),
      iataCode: 'AUH',
      icaoCode: 'OMAA',
      wikipediaUrl: '',
    );
    const arrival = Airport(
      name: 'John F. Kennedy International Airport',
      city: 'New York',
      countryCode: 'US',
      latLon: LatLng(40.6413, -73.7781),
      iataCode: 'JFK',
      icaoCode: 'KJFK',
      wikipediaUrl: '',
    );
    const route = FlightRoute(
      departure: departure,
      arrival: arrival,
      source: FlightRouteSource.fr24Historical,
      waypoints: [
        FlightWaypoint(latLon: LatLng(24.4330, 54.6511)),
        FlightWaypoint(latLon: LatLng(40.6413, -73.7781)),
      ],
      corridor: [
        LatLng(24.4330, 54.6511),
        LatLng(40.6413, 54.6511),
        LatLng(40.6413, -73.7781),
      ],
      metrics: FlightRouteMetrics(
        greatCircleDistanceKm: 11121,
        approxDurationMinutes: 780,
        actualDistanceKm: 12570,
        actualDurationMinutes: 823,
      ),
    );

    await tester.pumpWidget(
      _testApp(
        child: BlocProvider.value(
          value: subscriptionCubit,
          child: FlightRouteTabView(
            state: _loadedState(status: FlightStatus.upcoming, route: route),
            topPadding: 0,
          ),
        ),
      ),
    );

    expect(find.text('13h 45m'), findsOneWidget);
  });

  testWidgets('route tab in-progress keeps route progress card behavior', (
    tester,
  ) async {
    final subscriptionCubit = _buildSubscriptionCubit();
    addTearDown(subscriptionCubit.close);

    await tester.pumpWidget(
      _testApp(
        child: BlocProvider.value(
          value: subscriptionCubit,
          child: FlightRouteTabView(
            state: _loadedState(
              status: FlightStatus.inProgress,
              gpsData: const GpsData(latitude: 50.0, longitude: 10.0),
            ),
            topPadding: 0,
          ),
        ),
      ),
    );

    expect(find.text('Route progress'), findsOneWidget);
  });

  testWidgets(
    'dashboard GPS card shows stale age and manual help in searching',
    (tester) async {
      var helpTapped = false;

      await tester.pumpWidget(
        _testApp(
          child: GpsLiveStatusCard(
            gpsStatus: GpsStatus.searching,
            gpsData: const GpsData(latitude: 51, longitude: 0.1, accuracy: 12),
            gpsLastFixAt: DateTime.now().subtract(const Duration(seconds: 30)),
            onHelpTap: () => helpTapped = true,
          ),
        ),
      );

      expect(find.text('Searching for GPS'), findsOneWidget);
      expect(find.textContaining('Last fix'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pump();

      expect(helpTapped, isTrue);
    },
  );

  testWidgets('map GPS badge shows help affordance only when enabled', (
    tester,
  ) async {
    var helpTapped = false;

    await tester.pumpWidget(
      _testApp(
        child: Column(
          children: [
            MapGpsStatusBadge(
              gpsStatus: GpsStatus.searching,
              gpsData: null,
              onHelpTap: () => helpTapped = true,
            ),
            const SizedBox(height: 12),
            const MapGpsStatusBadge(
              gpsStatus: GpsStatus.gpsActive,
              gpsData: GpsData(latitude: 51, longitude: 0.1, accuracy: 10),
            ),
          ],
        ),
      ),
    );

    expect(find.text('?'), findsOneWidget);
    await tester.tap(find.text('?').first);
    await tester.pump();
    expect(helpTapped, isTrue);
  });

  testWidgets(
    'route tab keeps stale region/progress content visible while searching',
    (tester) async {
      final subscriptionCubit = _buildSubscriptionCubit();
      addTearDown(subscriptionCubit.close);

      await tester.pumpWidget(
        _testApp(
          child: BlocProvider.value(
            value: subscriptionCubit,
            child: FlightRouteTabView(
              state: _loadedState(
                status: FlightStatus.inProgress,
                gpsStatus: GpsStatus.searching,
                gpsData: const GpsData(latitude: 50.0, longitude: 10.0),
                gpsLastFixAt: DateTime.now().subtract(
                  const Duration(seconds: 25),
                ),
              ),
              topPadding: 0,
            ),
          ),
        ),
      );

      expect(find.text('Route progress'), findsOneWidget);
      expect(find.text('Showing last known data'), findsOneWidget);
    },
  );

  testWidgets('GPS help sheet shows recovery tips', (tester) async {
    await tester.pumpWidget(
      _testApp(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showGpsSignalHelpSheet(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('GPS troubleshooting'), findsOneWidget);
    expect(
      find.text('Looks like GPS signal is not reliable on your phone.'),
      findsOneWidget,
    );
    expect(find.text('Try this'), findsOneWidget);
    expect(find.text('Make sure Location Services are on'), findsOneWidget);
    expect(find.text('Move your phone closer to the window'), findsOneWidget);
    expect(
      find.text('Remove thick cases or metal accessories'),
      findsOneWidget,
    );
    expect(
      find.text('Hold your phone still for a few moments'),
      findsOneWidget,
    );
  });
}

Widget _testApp({required Widget child}) {
  return TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: child),
    ),
  );
}

FlightScreenLoaded _loadedState({
  required FlightStatus status,
  GpsStatus? gpsStatus,
  GpsData? gpsData,
  DateTime? gpsLastFixAt,
  FlightRoute? route,
}) {
  final flight = _buildFlight(status: status, route: route);
  return FlightScreenLoaded(
    flight: flight,
    routeRegions: flight.info.routeRegions,
    gps: FlightGpsState(
      data: gpsData,
      status:
          gpsStatus ??
          (gpsData == null ? GpsStatus.searching : GpsStatus.gpsActive),
      lastFixAt: gpsLastFixAt,
    ),
  );
}

Flight _buildFlight({
  required FlightStatus status,
  FlightRoute? route,
  FlightRouteInsights? routeInsights,
  FlightOfflineContent? offlineContent,
}) {
  final resolvedRoute = route ?? _testRoute();

  return Flight(
    id: 'flight-1',
    route: resolvedRoute,
    routeInsights: routeInsights ?? FlightInfo.empty.routeInsights,
    offlineContent: offlineContent ?? FlightInfo.empty.offlineContent,
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 1, 1)),
    status: status,
  );
}

FlightRoute _testRoute() {
  const departure = Airport(
    name: 'London Heathrow',
    city: 'London',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.45),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Munich Airport',
    city: 'Munich',
    countryCode: 'DE',
    latLon: LatLng(48.35, 11.79),
    iataCode: 'MUC',
    icaoCode: 'EDDM',
    wikipediaUrl: '',
  );
  const defaultRoute = FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(51.47, -0.45)),
      FlightWaypoint(latLon: LatLng(48.35, 11.79)),
    ],
    corridor: [
      LatLng(51.47, -0.45),
      LatLng(48.35, -0.45),
      LatLng(48.35, 11.79),
    ],
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 1487.5,
      approxDurationMinutes: 105,
    ),
  );

  return defaultRoute;
}

FlightRoute _linearTestRoute() {
  const departure = Airport(
    name: 'Origin Airport',
    city: 'Origin',
    countryCode: 'GB',
    latLon: LatLng(0, 0),
    iataCode: 'ORG',
    icaoCode: 'ORIG',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Arrival Airport',
    city: 'Arrival',
    countryCode: 'FR',
    latLon: LatLng(0, 10),
    iataCode: 'ARR',
    icaoCode: 'ARRI',
    wikipediaUrl: '',
  );

  return const FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(0, 0)),
      FlightWaypoint(latLon: LatLng(0, 10)),
    ],
    corridor: [LatLng(0, 0), LatLng(0, 10)],
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 1111.95,
      approxDurationMinutes: 111,
    ),
  );
}

double _coveredDistanceKmForTest(FlightRoute route, GpsData gpsData) {
  final airportToAirportDistanceKm = route.distanceInKm;
  final current = LatLng(gpsData.latitude!, gpsData.longitude!);
  final distance = const Distance();
  final distanceToDepartureKm = distance.as(
    LengthUnit.Kilometer,
    route.departure.latLon,
    current,
  );
  final distanceToArrivalKm = distance.as(
    LengthUnit.Kilometer,
    current,
    route.arrival.latLon,
  );
  final span = distanceToDepartureKm + distanceToArrivalKm;
  return (distanceToDepartureKm / span) * airportToAirportDistanceKm;
}

RouteRegion _buildRegion({
  String qid = 'region-1',
  required double pathFirstEncounterKm,
  required String name,
  Map<String, dynamic>? geometry,
}) {
  return RouteRegion(
    qid: qid,
    name: name,
    regionType: RouteRegionType.channel,
    pathFirstEncounterKm: pathFirstEncounterKm,
    pathLengthInsideKm: 120,
    geometry: RouteRegionGeometry(
      type: 'Polygon',
      geoJson: geometry ?? _polygon(7.0, 8.0),
    ),
  );
}

Map<String, dynamic> _polygon(double lonStart, double lonEnd) {
  return {
    'type': 'Polygon',
    'coordinates': [
      [
        [lonStart, -1.0],
        [lonEnd, -1.0],
        [lonEnd, 1.0],
        [lonStart, 1.0],
        [lonStart, -1.0],
      ],
    ],
  };
}

FlightArticle _buildArticle({required String qid, required String title}) {
  return FlightArticle(
    qid: qid,
    sourceUrl: 'https://en.wikipedia.org/wiki/${title.replaceAll(' ', '_')}',
    title: title,
    summary: 'Summary for $title',
    contentPlainText: 'Plain text for $title',
    contentHtml: '<p>HTML for $title</p>',
    languageCode: 'en',
    leadImageRelativePath: '',
    inlineImageRelativePaths: const [],
    attributionText: 'Source: Wikipedia contributors',
    licenseText: 'CC BY-SA',
    downloadedAt: DateTime(2026, 1, 1),
    sizeBytes: 1024,
  );
}

SubscriptionCubit _buildSubscriptionCubit() {
  return SubscriptionCubit(
    repository: _FakeSubscriptionRepository(),
    flightUnlockRepository: _FakeFlightUnlockRepository(),
    analytics: _FakeAppAnalytics(),
  );
}

class _FakeGpsDataProvider implements GpsDataProvider {
  void Function(GpsStatus status, {GpsData? data})? _onUpdate;

  @override
  Future<void> start({
    required void Function(GpsStatus status, {GpsData? data}) onUpdate,
  }) async {
    _onUpdate = onUpdate;
  }

  @override
  Future<void> stop() async {}

  void emit(GpsStatus status, {GpsData? data}) {
    _onUpdate?.call(status, data: data);
  }
}

class _FakeStartFlightUseCase implements StartFlightUseCase {
  _FakeStartFlightUseCase({required this.result});

  final bool result;

  @override
  Future<bool> call({required String flightId}) async => result;
}

class _NoopDeleteFlightUseCase implements DeleteFlightUseCase {
  @override
  Future<bool> call(String flightId) async => true;
}

class _NoopCompleteFlightUseCase implements CompleteFlightUseCase {
  @override
  Future<bool> call({
    required String flightId,
    required bool deleteOfflineData,
  }) async => true;
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  final _controller = StreamController<SubscriptionStatus>.broadcast();

  @override
  SubscriptionStatus get currentStatus => _status(isPro: false);

  @override
  Stream<SubscriptionStatus> get statusStream => _controller.stream;

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  Future<List<SubscriptionProduct>> getProducts() async => const [];

  @override
  Future<SubscriptionStatus> initialize() async => _status(isPro: false);

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async {
    return SubscriptionPaywallResult.notPresented;
  }

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<SubscriptionStatus> purchasePackage({
    required String packageId,
  }) async => _status(isPro: true);

  @override
  Future<SubscriptionStatus> refresh() async => _status(isPro: false);

  @override
  Future<SubscriptionStatus> restorePurchases() async => _status(isPro: false);
}

class _FakeFlightUnlockRepository implements FlightUnlockRepository {
  @override
  Stream<int> get balanceStream => const Stream<int>.empty();

  @override
  int get currentUnusedUnlockCount => 0;

  @override
  Future<void> close() async {}

  @override
  Future<int> consumeUnlock() async => 0;

  @override
  Future<FlightUnlockProduct?> getUnlockProduct() async => null;

  @override
  Future<int> initialize() async => 0;

  @override
  Future<FlightUnlockPurchaseResult> purchaseUnlock() async =>
      const FlightUnlockPurchaseResult.cancelled();

  @override
  Future<int> restoreUnlock() async => 0;
}

class _FakeAppAnalytics implements AppAnalytics {
  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {}

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {}

  @override
  Future<void> log(AnalyticsEvent event) async {}
}

SubscriptionStatus _status({required bool isPro}) {
  return SubscriptionStatus(
    isPro: isPro,
    entitlementId: isPro ? 'pro' : 'free',
    lastUpdatedAt: DateTime(2026, 1, 1),
  );
}
