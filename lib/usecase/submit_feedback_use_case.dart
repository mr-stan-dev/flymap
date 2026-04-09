import 'package:flymap/data/api/feedback_api.dart';
import 'package:flymap/entity/feedback_category.dart';
import 'package:flymap/logger.dart';

class SubmitFeedbackRequest {
  const SubmitFeedbackRequest({
    required this.message,
    required this.source,
    required this.isPro,
    required this.category,
    this.email,
  });

  final String message;
  final String source;
  final bool isPro;
  final FeedbackCategory category;
  final String? email;
}

abstract interface class SubmitFeedbackUseCase {
  Future<bool> call(SubmitFeedbackRequest request);
}

class DefaultSubmitFeedbackUseCase implements SubmitFeedbackUseCase {
  DefaultSubmitFeedbackUseCase({required FeedbackApi feedbackApi})
    : _feedbackApi = feedbackApi;

  final FeedbackApi _feedbackApi;
  final _logger = const Logger('SubmitFeedbackUseCase');

  @override
  Future<bool> call(SubmitFeedbackRequest request) async {
    final message = request.message.trim();
    if (message.isEmpty) return false;
    try {
      await _feedbackApi.submitFeedback(
        message: message,
        source: request.source,
        isPro: request.isPro,
        category: request.category,
        email: request.email,
      );
      return true;
    } catch (e) {
      _logger.error('submit failed: $e');
      return false;
    }
  }
}
