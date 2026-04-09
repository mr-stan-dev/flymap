import 'package:equatable/equatable.dart';
import 'package:flymap/entity/feedback_category.dart';

class FeedbackState extends Equatable {
  const FeedbackState({
    required this.category,
    required this.message,
    required this.email,
    required this.isSubmitting,
    required this.isSubmitted,
    required this.showSubmitError,
    required this.showEmailValidationError,
  });

  factory FeedbackState.initial() {
    return const FeedbackState(
      category: FeedbackCategory.general,
      message: '',
      email: '',
      isSubmitting: false,
      isSubmitted: false,
      showSubmitError: false,
      showEmailValidationError: false,
    );
  }

  final FeedbackCategory category;
  final String message;
  final String email;
  final bool isSubmitting;
  final bool isSubmitted;
  final bool showSubmitError;
  final bool showEmailValidationError;

  bool get canSubmit =>
      !isSubmitting && message.trim().isNotEmpty && !showEmailValidationError;

  FeedbackState copyWith({
    FeedbackCategory? category,
    String? message,
    String? email,
    bool? isSubmitting,
    bool? isSubmitted,
    bool? showSubmitError,
    bool? showEmailValidationError,
  }) {
    return FeedbackState(
      category: category ?? this.category,
      message: message ?? this.message,
      email: email ?? this.email,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      showSubmitError: showSubmitError ?? this.showSubmitError,
      showEmailValidationError:
          showEmailValidationError ?? this.showEmailValidationError,
    );
  }

  @override
  List<Object?> get props => [
    category,
    message,
    email,
    isSubmitting,
    isSubmitted,
    showSubmitError,
    showEmailValidationError,
  ];
}
