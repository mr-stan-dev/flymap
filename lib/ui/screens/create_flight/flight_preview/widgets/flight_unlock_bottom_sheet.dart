import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';

class FlightUnlockBottomSheet extends StatelessWidget {
  const FlightUnlockBottomSheet({
    required this.routePreview,
    required this.onUnlockFlight,
    required this.onViewProPlans,
    super.key,
  });

  final String? routePreview;
  final Future<void> Function(BuildContext sheetContext) onUnlockFlight;
  final Future<void> Function(BuildContext sheetContext) onViewProPlans;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, state) {
        final unlockCount = state.unusedFlightUnlockCount;
        final canUseExistingUnlock = unlockCount > 0;
        final product = state.flightUnlockProduct;
        final isLoadingUnlockOption =
            !canUseExistingUnlock &&
            state.isFlightUnlockLoading &&
            product == null;
        final showUnlockOption = canUseExistingUnlock || product != null;
        final optionAPrice = canUseExistingUnlock
            ? context.t.subscription.flightUnlockAvailableCount(
                count: unlockCount,
              )
            : product?.priceText ?? context.t.common.loading;
        final optionAButtonLabel = canUseExistingUnlock
            ? context.t.subscription.flightUnlockUseAction
            : context.t.subscription.flightUnlockAction;
        final optionAButtonEnabled = canUseExistingUnlock || product != null;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.subscription.flightUnlockSheetTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                if (isLoadingUnlockOption)
                  const _UnlockOptionsLoadingState()
                else ...[
                  if (showUnlockOption) ...[
                    _UnlockOptionCard(
                      title: context.t.subscription.flightUnlockOptionTitle,
                      subtitle: context.t.subscription.flightUnlockOptionBody,
                      supportingText: optionAPrice,
                      buttonLabel: optionAButtonLabel,
                      isPrimary: true,
                      isLoading: state.isFlightUnlockPurchaseLoading,
                      isEnabled:
                          optionAButtonEnabled && !state.isFlightUnlockLoading,
                      onPressed: () => onUnlockFlight(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _UnlockOptionCard(
                    title: context.t.subscription.flightUnlockProOptionTitle,
                    subtitle: context.t.subscription.flightUnlockProOptionBody,
                    buttonLabel: context.t.subscription.flightUnlockProAction,
                    isPrimary: false,
                    onPressed: () => onViewProPlans(context),
                  ),
                  if (showUnlockOption &&
                      state.flightUnlockErrorMessage?.trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: InlineMessage(
                        message: state.flightUnlockErrorMessage!,
                        tone: DsMessageTone.warning,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UnlockOptionsLoadingState extends StatelessWidget {
  const _UnlockOptionsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Text(
            context.t.common.loading,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _UnlockOptionCard extends StatelessWidget {
  const _UnlockOptionCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.supportingText,
    this.isPrimary = false,
    this.isLoading = false,
    this.isEnabled = true,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String? supportingText;
  final String buttonLabel;
  final bool isPrimary;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final button = isPrimary
        ? PrimaryButton(
            onPressed: isEnabled && !isLoading ? onPressed : null,
            label: buttonLabel,
            isLoading: isLoading,
          )
        : PremiumButton(
            label: buttonLabel,
            onPressed: isEnabled && !isLoading ? onPressed : null,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (supportingText?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              supportingText!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: button),
        ],
      ),
    );
  }
}
