import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/data/notifications/flight_notification_scheduler.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/forecast_notification_prefs.dart';
import 'package:flymap/ui/screens/settings/widgets/settings_group_card.dart';
import 'package:get_it/get_it.dart';

/// Settings card for the forecast alerts: shows the system permission
/// state (with an inline enable switch while it's missing) and the two
/// per-alert toggles, which are disabled until the permission is granted.
/// Every change re-syncs the scheduled notifications.
class NotificationsSettingsGroup extends StatefulWidget {
  const NotificationsSettingsGroup({super.key});

  @override
  State<NotificationsSettingsGroup> createState() =>
      _NotificationsSettingsGroupState();
}

class _NotificationsSettingsGroupState extends State<NotificationsSettingsGroup>
    with WidgetsBindingObserver {
  bool? _permissionGranted;
  bool _readyEnabled = true;
  bool _updatedEnabled = true;
  bool _requesting = false;

  NotificationPermissionService? get _permissionService =>
      GetIt.I.isRegistered<NotificationPermissionService>()
      ? GetIt.I.get<NotificationPermissionService>()
      : null;

  ForecastNotificationPrefs? get _prefs =>
      GetIt.I.isRegistered<ForecastNotificationPrefs>()
      ? GetIt.I.get<ForecastNotificationPrefs>()
      : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A grant made in system settings is picked up on return.
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final permissionService = _permissionService;
    final prefs = _prefs;
    if (permissionService == null || prefs == null) return;
    final granted = await permissionService.isGranted();
    final ready = await prefs.isReadyEnabled();
    final updated = await prefs.isUpdatedEnabled();
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _readyEnabled = ready;
      _updatedEnabled = updated;
    });
  }

  Future<void> _requestPermission() async {
    final permissionService = _permissionService;
    if (permissionService == null || _requesting) return;
    setState(() => _requesting = true);
    final granted = await permissionService.request();
    if (granted) _resync();
    if (mounted) {
      setState(() {
        _permissionGranted = granted;
        _requesting = false;
      });
    }
  }

  void _resync() {
    if (GetIt.I.isRegistered<FlightNotificationScheduler>()) {
      unawaited(GetIt.I.get<FlightNotificationScheduler>().resyncAll());
    }
  }

  Future<void> _setReady(bool enabled) async {
    setState(() => _readyEnabled = enabled);
    await _prefs?.setReadyEnabled(enabled);
    _resync();
  }

  Future<void> _setUpdated(bool enabled) async {
    setState(() => _updatedEnabled = enabled);
    await _prefs?.setUpdatedEnabled(enabled);
    _resync();
  }

  @override
  Widget build(BuildContext context) {
    // No DI (tests) — the whole card stays out of the list.
    if (_permissionService == null || _prefs == null) {
      return const SizedBox.shrink();
    }
    final strings = context.t.settings.notifications;
    final theme = Theme.of(context);
    final togglesEnabled = _permissionGranted == true;

    return SettingsGroupCard(
      title: strings.title,
      children: [
        if (_permissionGranted == false)
          ListTile(
            leading: const Icon(Icons.notifications_off_rounded),
            title: Text(
              strings.permissionOff,
              style: theme.textTheme.bodyMedium,
            ),
            trailing: Switch.adaptive(
              value: false,
              onChanged: _requesting
                  ? null
                  : (_) => unawaited(_requestPermission()),
            ),
          ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.event_available_rounded),
          title: Text(strings.readyTitle),
          subtitle: Text(strings.readySubtitle),
          value: togglesEnabled && _readyEnabled,
          onChanged: togglesEnabled
              ? (value) => unawaited(_setReady(value))
              : null,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.update_rounded),
          title: Text(strings.updatedTitle),
          subtitle: Text(strings.updatedSubtitle),
          value: togglesEnabled && _updatedEnabled,
          onChanged: togglesEnabled
              ? (value) => unawaited(_setUpdated(value))
              : null,
        ),
      ],
    );
  }
}
