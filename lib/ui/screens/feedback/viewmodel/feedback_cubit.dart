import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/feedback_category.dart';
import 'package:flymap/ui/screens/feedback/viewmodel/feedback_state.dart';
import 'package:flymap/usecase/submit_feedback_use_case.dart';

class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit({
    required SubmitFeedbackUseCase submitFeedbackUseCase,
    required String source,
    required bool isPro,
  }) : _submitFeedbackUseCase = submitFeedbackUseCase,
       _source = source,
       _isPro = isPro,
       super(FeedbackState.initial());

  final SubmitFeedbackUseCase _submitFeedbackUseCase;
  final String _source;
  final bool _isPro;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  void onCategoryChanged(FeedbackCategory category) {
    emit(state.copyWith(category: category, showSubmitError: false));
  }

  void onMessageChanged(String value) {
    emit(state.copyWith(message: value, showSubmitError: false));
  }

  void onEmailChanged(String value) {
    final trimmed = value.trim();
    final hasInvalidEmail =
        trimmed.isNotEmpty && !_emailRegex.hasMatch(trimmed);
    emit(
      state.copyWith(
        email: value,
        showEmailValidationError: hasInvalidEmail,
        showSubmitError: false,
      ),
    );
  }

  Future<void> submit() async {
    final message = state.message.trim();
    final email = state.email.trim();
    final hasInvalidEmail = email.isNotEmpty && !_emailRegex.hasMatch(email);

    if (state.isSubmitting) return;
    if (message.isEmpty || hasInvalidEmail) {
      emit(state.copyWith(showEmailValidationError: hasInvalidEmail));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showSubmitError: false));

    final ok = await _submitFeedbackUseCase.call(
      SubmitFeedbackRequest(
        message: message,
        source: _source,
        isPro: _isPro,
        category: state.category,
        email: email.isEmpty ? null : email,
      ),
    );

    if (ok) {
      emit(
        state.copyWith(
          isSubmitting: false,
          isSubmitted: true,
          showSubmitError: false,
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: false, showSubmitError: true));
  }
}
