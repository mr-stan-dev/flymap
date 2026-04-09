import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flymap/entity/feedback_category.dart';
import 'package:flymap/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FeedbackApi {
  FeedbackApi({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  static const _submitFeedbackFunction = 'submit_app_feedback';

  final FirebaseFunctions _functions;
  final _logger = const Logger('FeedbackApi');

  Future<void> submitFeedback({
    required String message,
    required String source,
    required bool isPro,
    required FeedbackCategory category,
    String? email,
  }) async {
    try {
      final metadata = await _buildMetadata(source: source, isPro: isPro);
      await _functions.httpsCallable(_submitFeedbackFunction).call({
        'message': message.trim(),
        'category': category.payloadValue,
        'email': (email == null || email.trim().isEmpty) ? null : email.trim(),
        'metadata': metadata,
      });
    } catch (e) {
      _logger.error('submit feedback failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _buildMetadata({
    required String source,
    required bool isPro,
  }) async {
    String? appVersion;
    String? buildNumber;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version.trim();
      buildNumber = packageInfo.buildNumber.trim();
    } catch (e) {
      _logger.log('could not read package info: $e');
    }

    final localeTag = PlatformDispatcher.instance.locale.toLanguageTag();
    return <String, dynamic>{
      'source': source.trim(),
      'platform': defaultTargetPlatform.name,
      'app_version': appVersion,
      'build_number': buildNumber,
      'locale': localeTag.isEmpty ? null : localeTag,
      'is_pro': isPro,
    };
  }
}
