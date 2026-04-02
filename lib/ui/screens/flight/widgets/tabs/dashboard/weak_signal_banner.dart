import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class WeakSignalBanner extends StatelessWidget {
  const WeakSignalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return InlineMessage(
      message: context.t.flight.dashboard.weakSignalBanner,
      tone: DsMessageTone.warning,
      icon: Icons.network_check,
    );
  }
}
