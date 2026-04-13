import 'package:flymap/entity/learn_article_progress.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';

class MarkLearnArticleSeenUseCase {
  MarkLearnArticleSeenUseCase({
    required LearnArticleProgressRepository repository,
  }) : _repository = repository;

  final LearnArticleProgressRepository _repository;

  Future<LearnArticleProgress> call({required String articleId}) {
    return _repository.markSeen(articleId);
  }
}
