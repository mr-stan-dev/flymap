import 'package:equatable/equatable.dart';

class LearnArticleContent extends Equatable {
  const LearnArticleContent({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.markdown,
    this.categoryOrder,
  });

  final String id;
  final String title;
  final String categoryId;
  final String markdown;
  final int? categoryOrder;

  String get categoryFolderName {
    if (categoryOrder == null) {
      return categoryId;
    }
    final prefix = categoryOrder!.toString().padLeft(2, '0');
    return '${prefix}_$categoryId';
  }

  @override
  List<Object?> get props => [id, title, categoryId, markdown, categoryOrder];
}
