import 'package:flymap/entity/learn_article_progress.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';

class GetLearnArticleProgressUseCase {
  GetLearnArticleProgressUseCase({
    required LearnArticleProgressRepository repository,
  }) : _repository = repository;

  final LearnArticleProgressRepository _repository;

  Future<Map<String, LearnArticleProgress>> call({
    required Iterable<String> articleIds,
  }) {
    return _repository.getByArticleIds(articleIds);
  }
}
