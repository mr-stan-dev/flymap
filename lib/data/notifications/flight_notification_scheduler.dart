import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/events/notifications/forecast_notification_events.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/policy/forecast_notification_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/forecast_notification_prefs.dart';
import 'package:timezone/timezone.dart' as tz;

/// The slice of the notifications plugin the scheduler needs — an
/// interface so tests can fake the system without platform channels.
abstract class ScheduledNotificationsGateway {
  Future<void> initialize({
    required void Function(String? payload) onNotificationTapped,
  });

  /// Payload of the notification that cold-started the app, if any.
  Future<String?> takeLaunchPayload();

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime whenUtc,
    required String payload,
  });

  Future<void> cancel(int id);
}

/// Real implementation over flutter_local_notifications. Inexact Android
/// alarms on purpose: minute precision is irrelevant for a forecast alert
/// and exact alarms need an extra Android 14 permission.
class LocalScheduledNotificationsGateway
    implements ScheduledNotificationsGateway {
  LocalScheduledNotificationsGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'flight_forecasts';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Flight reminders',
      channelDescription:
          'Reminders and weather forecasts for your saved flights',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> initialize({
    required void Function(String? payload) onNotificationTapped,
  }) async {
    // Permission is owned by NotificationPermissionService — never
    // auto-request from plugin init.
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) =>
          onNotificationTapped(response.payload),
    );
  }

  @override
  Future<String?> takeLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime whenUtc,
    required String payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(whenUtc, tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}

/// Places, replaces and cancels the two forecast alerts per saved flight
/// ([ForecastNotificationPolicy] decides when they fire), respecting the
/// system permission and the per-alert settings toggles. Notification taps
/// deep-link to the flight via [onOpenFlight].
class FlightNotificationScheduler {
  FlightNotificationScheduler({
    required ScheduledNotificationsGateway gateway,
    required AirportTimezoneService timezoneService,
    required NotificationPermissionService permissionService,
    required ForecastNotificationPrefs prefs,
    required FlightRepository flightRepository,
    AppAnalytics? analytics,
    DateTime Function()? now,
  }) : _gateway = gateway,
       _timezoneService = timezoneService,
       _permissionService = permissionService,
       _prefs = prefs,
       _flightRepository = flightRepository,
       _analytics = analytics,
       _now = now ?? DateTime.now;

  static const _logger = Logger('FlightNotificationScheduler');

  final ScheduledNotificationsGateway _gateway;
  final AirportTimezoneService _timezoneService;
  final NotificationPermissionService _permissionService;
  final ForecastNotificationPrefs _prefs;
  final FlightRepository _flightRepository;
  final AppAnalytics? _analytics;
  final DateTime Function() _now;

  /// Set by the app shell once navigation exists; receives the flight a
  /// tapped notification points at.
  void Function(Flight flight)? onOpenFlight;

  /// Stable per-flight, distinct per type, positive 32-bit.
  static int notificationId(String flightId, ForecastNotificationType type) =>
      ((flightId.hashCode & 0x3fffffff) << 1) | type.index;

  Future<void> initialize() async {
    await _gateway.initialize(onNotificationTapped: _handleTap);
    final launchPayload = await _gateway.takeLaunchPayload();
    if (launchPayload != null) _handleTap(launchPayload);
  }

  /// Re-derives the whole system schedule from the saved flights — used on
  /// app start (reboots, time changes) and whenever a toggle/permission
  /// flips.
  Future<void> resyncAll() async {
    try {
      final flights = await _flightRepository.getAllFlights();
      for (final flight in flights) {
        await syncForFlight(flight);
      }
    } catch (e) {
      _logger.error('resyncAll failed: $e');
    }
  }

  Future<void> syncForFlightId(String flightId) async {
    final flight = await _flightRepository.getFlightById(flightId);
    if (flight != null) await syncForFlight(flight);
  }

  Future<void> syncForFlight(Flight flight) async {
    // Idempotent: always clear both slots, then re-add what applies.
    await cancelForFlight(flight.id);

    final schedule = flight.schedule;
    if (schedule == null) return;
    // Every saved flight gets the two alerts at the same times. Pro flights
    // carry the weather-forecast copy (the feature they were promised); free
    // flights get a plain "your flight is coming up — check your map" nudge.
    // Both obey the same permission and per-alert settings toggles.
    if (!await _permissionService.isGranted()) return;

    final readyEnabled = await _prefs.isReadyEnabled();
    final updatedEnabled = await _prefs.isUpdatedEnabled();
    final now = _now().toUtc();

    for (final planned in ForecastNotificationPolicy.planFor(schedule)) {
      final enabled = switch (planned.type) {
        ForecastNotificationType.forecastReady => readyEnabled,
        ForecastNotificationType.forecastUpdated => updatedEnabled,
      };
      if (!enabled) continue;

      // Wall clock at the departure airport -> absolute instant; device
      // timezone when the airport's is unknown.
      final whenUtc =
          _timezoneService.localTimeToUtc(
            flight.route.departure,
            planned.localWallClock,
            hour: planned.localWallClock.hour,
            minute: planned.localWallClock.minute,
          ) ??
          planned.localWallClock.toUtc();
      if (!whenUtc.isAfter(now)) continue;

      try {
        await _gateway.schedule(
          id: notificationId(flight.id, planned.type),
          title: _title(planned.type, flight),
          body: _body(planned.type, flight),
          whenUtc: whenUtc,
          payload: flight.id,
        );
        unawaited(
          _analytics?.log(
            ForecastNotificationScheduledEvent(type: planned.type.name),
          ),
        );
      } catch (e) {
        _logger.error('schedule failed for ${flight.id}: $e');
      }
    }
  }

  Future<void> cancelForFlight(String flightId) async {
    for (final type in ForecastNotificationType.values) {
      try {
        await _gateway.cancel(notificationId(flightId, type));
      } catch (e) {
        _logger.error('cancel failed for $flightId: $e');
      }
    }
  }

  String _routeLabel(Flight flight) =>
      '${flight.route.departure.displayCode} → '
      '${flight.route.arrival.displayCode}';

  String _title(ForecastNotificationType type, Flight flight) {
    final strings = t.notifications;
    // Pro flights promise a forecast; free flights get a plain flight nudge.
    return switch ((type, flight.hasProAccess)) {
      (ForecastNotificationType.forecastReady, true) =>
        strings.forecastReadyTitle,
      (ForecastNotificationType.forecastUpdated, true) =>
        strings.forecastUpdatedTitle,
      (ForecastNotificationType.forecastReady, false) =>
        strings.reminderEarlyTitle,
      (ForecastNotificationType.forecastUpdated, false) =>
        strings.reminderTomorrowTitle,
    };
  }

  String _body(ForecastNotificationType type, Flight flight) {
    final strings = t.notifications;
    final route = _routeLabel(flight);
    return switch ((type, flight.hasProAccess)) {
      (ForecastNotificationType.forecastReady, true) =>
        strings.forecastReadyBody(route: route),
      (ForecastNotificationType.forecastUpdated, true) =>
        strings.forecastUpdatedBody(route: route),
      (ForecastNotificationType.forecastReady, false) =>
        strings.reminderEarlyBody(route: route),
      (ForecastNotificationType.forecastUpdated, false) =>
        strings.reminderTomorrowBody(route: route),
    };
  }

  void _handleTap(String? payload) {
    final flightId = payload?.trim() ?? '';
    if (flightId.isEmpty) return;
    unawaited(_analytics?.log(const ForecastNotificationOpenedEvent()));
    unawaited(() async {
      try {
        final flight = await _flightRepository.getFlightById(flightId);
        if (flight == null) return;
        onOpenFlight?.call(flight);
      } catch (e) {
        _logger.error('open from notification failed: $e');
      }
    }());
  }
}
