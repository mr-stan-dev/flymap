import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/widgets/wikipedia_logo_avatar.dart';

class ArticleTile extends StatelessWidget {
  const ArticleTile({required this.article, required this.onTap, super.key});

  final FlightArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.xxs,
        vertical: DsSpacing.xxs,
      ),
      leading: const WikipediaLogoAvatar(size: 36),
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
