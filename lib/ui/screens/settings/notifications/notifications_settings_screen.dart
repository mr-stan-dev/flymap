import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/widgets/notifications_settings_group.dart';

/// Dedicated screen for the forecast/reminder notification controls, reached
/// from a single row on the main settings screen.
class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.settings.notifications.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: const [NotificationsSettingsGroup()],
        ),
      ),
    );
  }
}
