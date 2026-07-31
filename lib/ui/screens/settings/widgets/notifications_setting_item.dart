import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/forecast_notification_prefs.dart';
import 'package:flymap/ui/screens/settings/notifications/notifications_settings_screen.dart';
import 'package:flymap/ui/screens/settings/widgets/setting_item.dart';
import 'package:get_it/get_it.dart';

/// Main-settings row that opens the dedicated notifications screen and shows
/// whether alerts are currently on (permission granted and at least one alert
/// toggle enabled).
class NotificationsSettingItem extends StatefulWidget {
  const NotificationsSettingItem({super.key});

  @override
  State<NotificationsSettingItem> createState() =>
      _NotificationsSettingItemState();
}

class _NotificationsSettingItemState extends State<NotificationsSettingItem>
    with WidgetsBindingObserver {
  bool? _granted;
  bool _anyEnabled = true;

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
      _granted = granted;
      _anyEnabled = ready || updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    // No DI (tests) — mirror the group and stay out of the list.
    if (_permissionService == null || _prefs == null) {
      return const SizedBox.shrink();
    }
    final strings = context.t.settings.notifications;
    final isOn = _granted == true && _anyEnabled;
    return SettingItem(
      title: strings.title,
      subtitle: isOn ? strings.summaryOn : strings.summaryOff,
      leading: const Icon(Icons.notifications_outlined),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationsSettingsScreen(),
          ),
        );
        // Reflect any change made on the screen (permission / toggles).
        await _refresh();
      },
    );
  }
}
