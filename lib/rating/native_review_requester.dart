import 'package:in_app_review/in_app_review.dart';

abstract interface class NativeReviewRequester {
  Future<void> requestReview();
}

class DefaultNativeReviewRequester implements NativeReviewRequester {
  DefaultNativeReviewRequester({required InAppReview inAppReview})
    : _inAppReview = inAppReview;

  final InAppReview _inAppReview;

  @override
  Future<void> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {
      // Native review prompts are best-effort and controlled by the platform.
    }
  }
}
