import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';

class LeaveFeedbackSettingItem extends StatelessWidget {
  const LeaveFeedbackSettingItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.feedback_outlined),
      title: Text(
        context.t.settings.leaveFeedback,
        style: theme.textTheme.titleMedium,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openFeedback(context),
    );
  }

  Future<void> _openFeedback(BuildContext context) async {
    final submitted = await AppRouter.goToFeedback(
      context,
      source: 'settings_leave_feedback',
      isPro: context.read<SubscriptionCubit>().state.isPro,
    );
    if (!context.mounted || !submitted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t.settings.feedbackThanks)));
  }
}
