import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class FlightDownloadCompletion extends StatelessWidget {
  const FlightDownloadCompletion({super.key});

  @override
  Widget build(BuildContext context) {
    return SuccessStateView(
      title: context.t.preview.downloadComplete,
      subtitle: context.t.preview.flightSaved,
      footer: context.t.preview.navigatingHome,
    );
  }
}
