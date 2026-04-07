import 'package:equatable/equatable.dart';

class PoiWikiPreview extends Equatable {
  const PoiWikiPreview({
    required this.qid,
    required this.title,
    required this.summary,
    this.htmlContent = '',
    required this.sourceUrl,
    required this.languageCode,
  });

  final String qid;
  final String title;
  final String summary;
  final String htmlContent;
  final String sourceUrl;
  final String languageCode;

  @override
  List<Object?> get props => [
    qid,
    title,
    summary,
    htmlContent,
    sourceUrl,
    languageCode,
  ];
}
