import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class LearnArticleScreen extends StatelessWidget {
  const LearnArticleScreen({required this.article, super.key});

  final LearnArticleContent article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final markdownStyle = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        height: 1.45,
      ),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        height: 1.45,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.7),
            width: 3,
          ),
        ),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            width: 2,
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: SafeArea(
        child: Markdown(
          data: article.markdown,
          styleSheet: markdownStyle,
          sizedImageBuilder: (config) {
            final src = config.uri.toString().trim();
            final assetPath = _assetPathForMarkdownImage(src);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  assetPath,
                  width: config.width,
                  height: config.height,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            );
          },
          onTapLink: (text, href, title) async {
            final link = href?.trim();
            if (link == null || link.isEmpty) return;
            final uri = Uri.tryParse(link);
            if (uri == null) return;
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (!launched && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.t.settings.couldNotOpenUrl(url: link)),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  String _assetPathForMarkdownImage(String source) {
    if (source.startsWith('assets/')) return source;
    if (source.startsWith('/')) return source.substring(1);
    return 'assets/data/learn/articles/$source';
  }
}
