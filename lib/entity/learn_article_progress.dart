import 'package:equatable/equatable.dart';

class LearnArticleProgress extends Equatable {
  const LearnArticleProgress({this.isFavorite = false, this.isSeen = false});

  static const LearnArticleProgress empty = LearnArticleProgress();

  final bool isFavorite;
  final bool isSeen;

  LearnArticleProgress copyWith({bool? isFavorite, bool? isSeen}) {
    return LearnArticleProgress(
      isFavorite: isFavorite ?? this.isFavorite,
      isSeen: isSeen ?? this.isSeen,
    );
  }

  bool get hasAnyState => isFavorite || isSeen;

  @override
  List<Object?> get props => [isFavorite, isSeen];
}
