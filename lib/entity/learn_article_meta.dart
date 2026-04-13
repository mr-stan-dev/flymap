import 'package:equatable/equatable.dart';
import 'package:flymap/entity/learn_access.dart';

class LearnArticleMeta extends Equatable {
  const LearnArticleMeta({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.access,
    this.order,
    this.categoryOrder,
  });

  final String id;
  final String title;
  final String categoryId;
  final LearnAccess access;
  final int? order;
  final int? categoryOrder;

  bool get isProOnly => access == LearnAccess.pro;

  String get categoryFolderName {
    if (categoryOrder == null) {
      return categoryId;
    }
    final prefix = categoryOrder!.toString().padLeft(2, '0');
    return '${prefix}_$categoryId';
  }

  String get markdownFileName {
    return '$id.md';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    categoryId,
    access,
    order,
    categoryOrder,
  ];
}
