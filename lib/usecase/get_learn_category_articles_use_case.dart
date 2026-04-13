import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/repository/learn_repository.dart';

class GetLearnCategoryArticlesUseCase {
  GetLearnCategoryArticlesUseCase({required LearnRepository repository})
    : _repository = repository;

  final LearnRepository _repository;

  Future<List<LearnArticleMeta>> call({required String categoryId}) async {
    return _repository.getArticles(categoryId: categoryId);
  }
}
