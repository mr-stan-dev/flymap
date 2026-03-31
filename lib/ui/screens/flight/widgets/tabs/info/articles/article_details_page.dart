import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/article_html_composer.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/offline_article_html_view.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/plain_text_article_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailsPage extends StatelessWidget {
  const ArticleDetailsPage({required this.article, super.key});

  final FlightArticle article;

  @override
  Widget build(BuildContext context) {
    final hasHtml = article.contentHtml.trim().isNotEmpty;
    final htmlContent = hasHtml ? composeScrollableHtml(article) : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
        actions: [
          IconButton(
            tooltip: 'Open source page',
            onPressed: () => _openSource(article.sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.md,
            DsSpacing.sm,
            DsSpacing.md,
            DsSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: hasHtml
                    ? OfflineArticleHtmlView(
                        htmlContent: htmlContent,
                        articleTitle: article.title,
                      )
                    : PlainTextArticleView(
                        article: article,
                        onOpenSource: () => _openSource(article.sourceUrl),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSource(String sourceUrl) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
