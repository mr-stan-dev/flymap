import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/feedback_category.dart';
import 'package:flymap/ui/screens/feedback/viewmodel/feedback_cubit.dart';
import 'package:flymap/usecase/submit_feedback_use_case.dart';

void main() {
  group('FeedbackCubit', () {
    test('initial state preselects general category', () {
      final cubit = FeedbackCubit(
        submitFeedbackUseCase: _FakeSubmitFeedbackUseCase(),
        source: 'test_source',
        isPro: false,
      );

      expect(cubit.state.category, FeedbackCategory.general);
      expect(cubit.state.message, isEmpty);
      expect(cubit.state.email, isEmpty);
    });

    test('submit sends request with optional email', () async {
      final useCase = _FakeSubmitFeedbackUseCase();
      final cubit = FeedbackCubit(
        submitFeedbackUseCase: useCase,
        source: 'test_source',
        isPro: true,
      );

      cubit.onCategoryChanged(FeedbackCategory.featureRequest);
      cubit.onMessageChanged('Please add weather overlays');
      cubit.onEmailChanged('pilot@example.com');
      await cubit.submit();

      expect(cubit.state.isSubmitted, isTrue);
      expect(useCase.requests.single.source, 'test_source');
      expect(useCase.requests.single.isPro, isTrue);
      expect(useCase.requests.single.category, FeedbackCategory.featureRequest);
      expect(useCase.requests.single.message, 'Please add weather overlays');
      expect(useCase.requests.single.email, 'pilot@example.com');
    });

    test('invalid email blocks submit', () async {
      final useCase = _FakeSubmitFeedbackUseCase();
      final cubit = FeedbackCubit(
        submitFeedbackUseCase: useCase,
        source: 'test_source',
        isPro: false,
      );

      cubit.onMessageChanged('Something is wrong');
      cubit.onEmailChanged('invalid-email');
      await cubit.submit();

      expect(useCase.requests, isEmpty);
      expect(cubit.state.showEmailValidationError, isTrue);
      expect(cubit.state.isSubmitted, isFalse);
    });

    test('failed submit surfaces submit error', () async {
      final useCase = _FakeSubmitFeedbackUseCase(result: false);
      final cubit = FeedbackCubit(
        submitFeedbackUseCase: useCase,
        source: 'test_source',
        isPro: false,
      );

      cubit.onMessageChanged('Send should fail');
      await cubit.submit();

      expect(useCase.requests, hasLength(1));
      expect(cubit.state.showSubmitError, isTrue);
      expect(cubit.state.isSubmitted, isFalse);
      expect(cubit.state.isSubmitting, isFalse);
    });
  });
}

class _FakeSubmitFeedbackUseCase implements SubmitFeedbackUseCase {
  _FakeSubmitFeedbackUseCase({this.result = true});

  final bool result;
  final List<SubmitFeedbackRequest> requests = <SubmitFeedbackRequest>[];

  @override
  Future<bool> call(SubmitFeedbackRequest request) async {
    requests.add(request);
    return result;
  }
}
