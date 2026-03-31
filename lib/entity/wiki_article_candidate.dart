import 'package:equatable/equatable.dart';

class WikiArticleCandidate extends Equatable {
  const WikiArticleCandidate({
    required this.url,
    required this.title,
    required this.languageCode,
  });

  final String url;
  final String title;
  final String languageCode;

  @override
  List<Object?> get props => [url, title, languageCode];
}
