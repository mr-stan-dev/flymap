import 'package:equatable/equatable.dart';
import 'package:flymap/entity/learn_article_meta.dart';

class LearnCategory extends Equatable {
  const LearnCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAssetPath,
    required this.articles,
  });

  final String id;
  final String title;
  final String description;
  final String imageAssetPath;
  final List<LearnArticleMeta> articles;

  int get articleCount => articles.length;

  @override
  List<Object?> get props => [id, title, description, imageAssetPath, articles];
}
