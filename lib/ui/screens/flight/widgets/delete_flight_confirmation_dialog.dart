import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/size_utils.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class DeleteFlightConfirmationDialog extends StatelessWidget {
  const DeleteFlightConfirmationDialog({
    required this.reclaimedBytes,
    super.key,
  });

  final int reclaimedBytes;

  static Future<bool?> show(
    BuildContext context, {
    required int reclaimedBytes,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) =>
          DeleteFlightConfirmationDialog(reclaimedBytes: reclaimedBytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageLabel = SizeUtils.formatBytes(reclaimedBytes);

    return AlertDialog(
      title: Text(context.t.flight.deleteDialogTitle),
      content: Text(context.t.flight.deleteDialogMessage(size: storageLabel)),
      actions: [
        SecondaryButton(
          label: context.t.common.cancel,
          onPressed: () => Navigator.of(context).pop(false),
          expand: false,
        ),
        DestructiveButton(
          label: context.t.flight.yes,
          onPressed: () => Navigator.of(context).pop(true),
          expand: false,
        ),
      ],
    );
  }
}
