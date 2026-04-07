import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/common/html_content_page.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/article_html_composer.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/plain_text_article_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailsPage extends StatelessWidget {
  const ArticleDetailsPage({required this.article, super.key});

  final FlightArticle article;

  @override
  Widget build(BuildContext context) {
    final hasHtml = article.contentHtml.trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = colorScheme.surface;
    final htmlContent = hasHtml
        ? composeScrollableHtml(
            article: article,
            backgroundColor: pageBackground,
            textColor: colorScheme.onSurface,
            mutedTextColor: colorScheme.onSurfaceVariant,
            dividerColor: colorScheme.outlineVariant,
            isDarkMode: isDarkMode,
          )
        : '';
    if (hasHtml) {
      return HtmlContentPage(
        title: article.title,
        htmlContent: htmlContent,
        sourceUrl: article.sourceUrl,
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: Text(article.title),
        actions: [
          IconButton(
            tooltip: context.t.flight.info.openSourcePageTooltip,
            onPressed: () => _openSource(article.sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ColoredBox(
          color: pageBackground,
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
                  child: PlainTextArticleView(
                    article: article,
                    onOpenSource: () => _openSource(article.sourceUrl),
                  ),
                ),
              ],
            ),
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
