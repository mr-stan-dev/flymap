import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class WeakSignalBanner extends StatelessWidget {
  const WeakSignalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const InlineMessage(
      message: 'Weak GPS signal. Values may drift until accuracy improves.',
      tone: DsMessageTone.warning,
      icon: Icons.network_check,
    );
  }
}
