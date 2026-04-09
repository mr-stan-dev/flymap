import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class RateAppDialog extends StatelessWidget {
  const RateAppDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RateAppDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.t.settings.rateDialogTitle,
        style: context.textTheme.title24Medium,
      ),
      content: Text(
        context.t.settings.rateDialogBody,
        style: context.textTheme.body16Regular,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.t.settings.rateDialogNo),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.t.settings.rateDialogYes),
        ),
      ],
    );
  }
}
