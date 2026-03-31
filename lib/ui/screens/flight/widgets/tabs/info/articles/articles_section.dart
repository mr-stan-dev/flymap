import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/article_details_page.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/articles/article_tile.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/section_card.dart';

class ArticlesSection extends StatelessWidget {
  const ArticlesSection({required this.articles, super.key});

  final List<FlightArticle> articles;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      title: 'Offline Articles',
      child: articles.isEmpty
          ? const Text('No offline articles downloaded.')
          : Column(
              children: [
                for (final entry in articles.asMap().entries) ...[
                  ArticleTile(
                    article: entry.value,
                    onTap: () => _openArticleDetails(context, entry.value),
                  ),
                  if (entry.key < articles.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }

  void _openArticleDetails(BuildContext context, FlightArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticleDetailsPage(article: article),
      ),
    );
  }
}
