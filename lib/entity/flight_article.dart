import 'package:equatable/equatable.dart';

class FlightArticle extends Equatable {
  const FlightArticle({
    required this.sourceUrl,
    required this.title,
    required this.summary,
    required this.contentPlainText,
    required this.contentHtml,
    required this.languageCode,
    required this.leadImageRelativePath,
    required this.inlineImageRelativePaths,
    required this.attributionText,
    required this.licenseText,
    required this.downloadedAt,
    required this.sizeBytes,
  });

  final String sourceUrl;
  final String title;
  final String summary;
  final String contentPlainText;
  final String contentHtml;
  final String languageCode;
  final String leadImageRelativePath;
  final List<String> inlineImageRelativePaths;
  final String attributionText;
  final String licenseText;
  final DateTime downloadedAt;
  final int sizeBytes;

  @override
  List<Object?> get props => [
    sourceUrl,
    title,
    summary,
    contentPlainText,
    contentHtml,
    languageCode,
    leadImageRelativePath,
    inlineImageRelativePaths,
    attributionText,
    licenseText,
    downloadedAt,
    sizeBytes,
  ];
}
