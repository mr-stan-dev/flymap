import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/repository/learn_repository.dart';

class GetLearnArticleContentUseCase {
  GetLearnArticleContentUseCase({required LearnRepository repository})
    : _repository = repository;

  final LearnRepository _repository;

  Future<LearnArticleContent> call({required String articleId}) async {
    return _repository.getArticleContent(articleId: articleId);
  }
}
