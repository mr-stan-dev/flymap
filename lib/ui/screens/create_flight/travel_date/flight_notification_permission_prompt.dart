import 'package:flutter/material.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/policy/forecast_notification_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/forecast_notification_prefs.dart';
import 'package:get_it/get_it.dart';

/// Owns the contextual notification permission ask during flight creation.
///
/// The app explanation is shown only when the day-before reminder still has
/// a future delivery time. The system prompt is deferred until the user
/// explicitly accepts our explanation.
class FlightNotificationPermissionPrompt {
  const FlightNotificationPermissionPrompt._();

  /// Returns whether flight creation should continue. Dismissing the app
  /// dialog without choosing an action returns false and leaves the user on
  /// the current screen; every non-prompt path returns true.
  static Future<bool> showIfEligible({
    required BuildContext context,
    required FlightSchedule schedule,
    required Airport departure,
    DateTime Function()? now,
  }) async {
    final getIt = GetIt.I;
    if (!getIt.isRegistered<NotificationPermissionService>()) return true;

    final permissionService = getIt.get<NotificationPermissionService>();
    try {
      if (await permissionService.isGranted()) return true;
    } catch (_) {
      // Permission lookup must never block flight creation.
      return true;
    }

    if (getIt.isRegistered<ForecastNotificationPrefs>()) {
      try {
        if (!await getIt.get<ForecastNotificationPrefs>().isUpdatedEnabled()) {
          return true;
        }
      } catch (_) {
        // Be conservative: do not ask for permission for a reminder whose
        // user preference could not be read.
        return true;
      }
    }

    final eligible = await isDayBeforeReminderEligible(
      schedule: schedule,
      departure: departure,
      timezoneService: getIt.isRegistered<AirportTimezoneService>()
          ? getIt.get<AirportTimezoneService>()
          : null,
      now: now?.call() ?? DateTime.now(),
    );
    if (!eligible || !context.mounted) return true;

    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final t = dialogContext.t.createFlight.travelDate;
        return AlertDialog(
          icon: const Icon(Icons.notifications_active_rounded, size: 48),
          title: Text(t.notificationPermissionTitle),
          content: Text(t.notificationPermissionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.notificationPermissionNotNow),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.notificationPermissionAllow),
            ),
          ],
        );
      },
    );

    if (shouldRequest == true) {
      try {
        await permissionService.request();
      } catch (_) {
        // A platform failure must not block the user from continuing.
      }
    }
    return shouldRequest != null;
  }

  /// Mirrors the scheduler's eligibility rule for the day-before reminder.
  static Future<bool> isDayBeforeReminderEligible({
    required FlightSchedule schedule,
    required Airport departure,
    required DateTime now,
    AirportTimezoneService? timezoneService,
  }) async {
    PlannedForecastNotification? planned;
    for (final notification in ForecastNotificationPolicy.planFor(schedule)) {
      if (notification.type == ForecastNotificationType.forecastUpdated) {
        planned = notification;
        break;
      }
    }
    if (planned == null) return false;

    DateTime? resolvedUtc;
    if (timezoneService != null) {
      try {
        await timezoneService.ensureReady();
        resolvedUtc = timezoneService.localTimeToUtc(
          departure,
          planned.localWallClock,
          hour: planned.localWallClock.hour,
          minute: planned.localWallClock.minute,
        );
      } catch (_) {
        // Match scheduler fallback when airport timezone data is unavailable.
      }
    }
    final reminderUtc = resolvedUtc ?? planned.localWallClock.toUtc();
    return reminderUtc.isAfter(now.toUtc());
  }
}
