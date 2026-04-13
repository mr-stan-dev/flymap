import 'package:flymap/entity/learn_access.dart';
import 'package:flymap/repository/learn_repository.dart';

class CanOpenLearnArticleUseCase {
  CanOpenLearnArticleUseCase({required LearnRepository repository})
    : _repository = repository;

  final LearnRepository _repository;

  bool call({required LearnAccess articleAccess, required bool isProUser}) {
    return _repository.canOpenArticle(
      articleAccess: articleAccess,
      isProUser: isProUser,
    );
  }
}
