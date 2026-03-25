import 'package:flutter/material.dart';
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
      title: const Text('Are you sure?'),
      content: Text(
        'This will permanently delete this flight.\n\n'
        'Space to be regained: $storageLabel.',
      ),
      actions: [
        SecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
          expand: false,
        ),
        DestructiveButton(
          label: 'Yes',
          onPressed: () => Navigator.of(context).pop(true),
          expand: false,
        ),
      ],
    );
  }
}
