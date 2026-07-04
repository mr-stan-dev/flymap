import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

enum AppAdvocacyAction { share, rate, notNow }

class AppAdvocacyDialog extends StatelessWidget {
  const AppAdvocacyDialog({
    required this.showRateAction,
    required this.showShareAction,
    super.key,
  });

  final bool showRateAction;
  final bool showShareAction;

  static Future<AppAdvocacyAction?> show(
    BuildContext context, {
    required bool showRateAction,
    required bool showShareAction,
  }) {
    return showDialog<AppAdvocacyAction>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppAdvocacyDialog(
        showRateAction: showRateAction,
        showShareAction: showShareAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.t.settings.advocacyDialogTitle,
        style: context.textTheme.title24Medium,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t.settings.advocacyDialogBody,
            style: context.textTheme.body16Regular,
          ),
          const SizedBox(height: 24),
          if (showRateAction) ...[
            PrimaryButton(
              label: context.t.settings.advocacyDialogRate,
              leadingIcon: Icons.star_outline,
              onPressed: () {
                Navigator.of(context).pop(AppAdvocacyAction.rate);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (showShareAction) ...[
            PrimaryButton(
              label: context.t.settings.advocacyDialogShare,
              leadingIcon: Icons.share_outlined,
              onPressed: () {
                Navigator.of(context).pop(AppAdvocacyAction.share);
              },
            ),
            const SizedBox(height: 8),
          ],
          TertiaryButton(
            label: context.t.settings.advocacyDialogNotNow,
            compact: true,
            onPressed: () {
              Navigator.of(context).pop(AppAdvocacyAction.notNow);
            },
          ),
        ],
      ),
    );
  }
}
