enum FeedbackCategory { general, featureRequest, bugReport }

extension FeedbackCategoryPayload on FeedbackCategory {
  String get payloadValue {
    return switch (this) {
      FeedbackCategory.general => 'general',
      FeedbackCategory.featureRequest => 'feature_request',
      FeedbackCategory.bugReport => 'bug_report',
    };
  }
}
