import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/feedback_category.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/feedback/feedback_screen_args.dart';
import 'package:flymap/ui/screens/feedback/viewmodel/feedback_cubit.dart';
import 'package:flymap/ui/screens/feedback/viewmodel/feedback_state.dart';
import 'package:flymap/usecase/submit_feedback_use_case.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({
    required this.args,
    required this.submitFeedbackUseCase,
    super.key,
  });

  final FeedbackScreenArgs args;
  final SubmitFeedbackUseCase submitFeedbackUseCase;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeedbackCubit>(
      create: (_) => FeedbackCubit(
        submitFeedbackUseCase: submitFeedbackUseCase,
        source: args.source,
        isPro: args.isPro,
      ),
      child: const _FeedbackScreenView(),
    );
  }
}

class _FeedbackScreenView extends StatelessWidget {
  const _FeedbackScreenView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackCubit, FeedbackState>(
      listenWhen: (previous, current) =>
          previous.isSubmitted != current.isSubmitted,
      listener: (context, state) {
        if (!state.isSubmitted) return;
        Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        final cubit = context.read<FeedbackCubit>();
        return Scaffold(
          appBar: AppBar(title: Text(context.t.settings.feedbackTitle)),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      Text(
                        context.t.settings.feedbackBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t.settings.feedbackCategoryTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: DsSpacing.xs,
                        runSpacing: DsSpacing.xs,
                        children: [
                          SelectionChip(
                            label: context.t.settings.feedbackCategoryGeneral,
                            selected:
                                state.category == FeedbackCategory.general,
                            showCheckmark: false,
                            onPressed: state.isSubmitting
                                ? null
                                : () => cubit.onCategoryChanged(
                                    FeedbackCategory.general,
                                  ),
                          ),
                          SelectionChip(
                            label: context
                                .t
                                .settings
                                .feedbackCategoryFeatureRequest,
                            selected:
                                state.category ==
                                FeedbackCategory.featureRequest,
                            showCheckmark: false,
                            onPressed: state.isSubmitting
                                ? null
                                : () => cubit.onCategoryChanged(
                                    FeedbackCategory.featureRequest,
                                  ),
                          ),
                          SelectionChip(
                            label: context.t.settings.feedbackCategoryBugReport,
                            selected:
                                state.category == FeedbackCategory.bugReport,
                            showCheckmark: false,
                            onPressed: state.isSubmitting
                                ? null
                                : () => cubit.onCategoryChanged(
                                    FeedbackCategory.bugReport,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 800,
                        enabled: !state.isSubmitting,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        onChanged: cubit.onMessageChanged,
                        decoration: InputDecoration(
                          hintText: context.t.settings.feedbackHint,
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        enabled: !state.isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onChanged: cubit.onEmailChanged,
                        decoration: InputDecoration(
                          hintText: context.t.settings.feedbackEmailHint,
                          errorText: state.showEmailValidationError
                              ? context.t.settings.feedbackEmailInvalid
                              : null,
                        ),
                      ),
                      if (state.showSubmitError) ...[
                        const SizedBox(height: 10),
                        Text(
                          context.t.settings.feedbackSendFailed,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: PrimaryButton(
                    label: context.t.settings.feedbackSend,
                    onPressed: state.canSubmit ? cubit.submit : null,
                    isLoading: state.isSubmitting,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
