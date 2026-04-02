import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class PlainTextArticleView extends StatelessWidget {
  const PlainTextArticleView({
    required this.article,
    required this.onOpenSource,
    super.key,
  });

  final FlightArticle article;
  final VoidCallback onOpenSource;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.summary.trim().isNotEmpty) ...[
            Text(
              article.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
          ],
          SelectableText(article.contentPlainText),
          const SizedBox(height: DsSpacing.md),
          SelectionChip(
            label: context.t.flight.info.openSource,
            onPressed: onOpenSource,
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            article.attributionText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: DsSpacing.xxs),
          Text(
            article.licenseText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
