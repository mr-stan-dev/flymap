import 'package:equatable/equatable.dart';
import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/entity/learn_category.dart';

sealed class LearnState extends Equatable {
  const LearnState();

  @override
  List<Object?> get props => [];
}

final class LearnLoading extends LearnState {
  const LearnLoading();
}

final class LearnLoaded extends LearnState {
  const LearnLoaded({required this.categories});

  final List<LearnCategory> categories;

  @override
  List<Object?> get props => [categories];
}

final class LearnError extends LearnState {
  const LearnError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class LearnArticleTapResult extends Equatable {
  const LearnArticleTapResult();

  @override
  List<Object?> get props => [];
}

final class LearnOpenArticle extends LearnArticleTapResult {
  const LearnOpenArticle(this.article);

  final LearnArticleContent article;

  @override
  List<Object?> get props => [article];
}

final class LearnUpgradeRequired extends LearnArticleTapResult {
  const LearnUpgradeRequired();
}

final class LearnOfflineUpgradeBlocked extends LearnArticleTapResult {
  const LearnOfflineUpgradeBlocked({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

final class LearnOpenArticleFailed extends LearnArticleTapResult {
  const LearnOpenArticleFailed({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
