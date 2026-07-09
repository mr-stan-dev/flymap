import 'package:flymap/analytics/events/analytics_event.dart';

class LearnCategoryOpenedEvent extends FirebaseAnalyticsEvent {
  const LearnCategoryOpenedEvent({
    required this.categoryId,
    required this.articleCount,
  });

  final String categoryId;
  final int articleCount;

  @override
  String get firebaseEventName => 'learn_category_opened';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'category_id': categoryId,
    'article_count': articleCount,
  };
}
