import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/data/notifications/flight_notification_scheduler.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/policy/forecast_notification_policy.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:get_it/get_it.dart';

/// DEBUG-ONLY tools. Not localized and never shown in release builds — the
/// settings screen gates it behind `kDebugMode`.
class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  Flight? _flight;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFlight();
  }

  Future<void> _loadFlight() async {
    final flights = await GetIt.I.get<FlightRepository>().getAllFlights();
    if (!mounted) return;
    setState(() {
      _flight = _pickPreviewFlight(flights);
      _loading = false;
    });
  }

  /// Prefer the nearest UPCOMING dated flight (most realistic), then the most
  /// recent dated flight, then any flight at all.
  Flight? _pickPreviewFlight(List<Flight> flights) {
    final now = DateTime.now();
    final dated = flights.where((f) => f.schedule != null).toList()
      ..sort((a, b) => a.schedule!.travelDate.compareTo(b.schedule!.travelDate));
    final upcoming = dated.where((f) => f.schedule!.travelDate.isAfter(now));
    if (upcoming.isNotEmpty) return upcoming.first;
    if (dated.isNotEmpty) return dated.last;
    if (flights.isNotEmpty) return flights.first;
    return null;
  }

  Future<void> _send(ForecastNotificationType type) async {
    final flight = _flight;
    if (flight == null) return;

    final permission = GetIt.I.get<NotificationPermissionService>();
    if (!await permission.isGranted()) {
      await permission.request();
    }
    if (!await permission.isGranted()) {
      _toast('Notification permission not granted');
      return;
    }

    await GetIt.I.get<FlightNotificationScheduler>().sendPreview(flight, type);
    _toast('Sent — check your notification shade');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flight = _flight;
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Notification test',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  flight == null
                      ? 'No saved flight found — create one to preview with a '
                            'real route and tier.'
                      : _flightSummary(flight),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: flight == null
                      ? null
                      : () => unawaited(
                          _send(ForecastNotificationType.forecastReady),
                        ),
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Send "6 days before" notification'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: flight == null
                      ? null
                      : () => unawaited(
                          _send(ForecastNotificationType.forecastUpdated),
                        ),
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Send "1 day before" notification'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Fires immediately with the selected flight\'s real copy '
                  '(Pro forecast vs free reminder) and deep-links to the flight '
                  'when tapped.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }

  String _flightSummary(Flight flight) {
    final route =
        '${flight.route.departure.displayCode} → '
        '${flight.route.arrival.displayCode}';
    final tier = flight.hasProAccess
        ? 'Pro (forecast copy)'
        : 'Free (reminder copy)';
    final date = flight.schedule?.travelDate;
    final dateLabel = date == null
        ? 'no date'
        : date.toIso8601String().split('T').first;
    return 'Using: $route · $tier · $dateLabel';
  }
}
