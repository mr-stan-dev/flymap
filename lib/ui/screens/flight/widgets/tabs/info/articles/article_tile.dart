import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_article.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class ArticleTile extends StatelessWidget {
  const ArticleTile({required this.article, required this.onTap, super.key});

  static const _wikipediaLogoIconAsset =
      'assets/images/wikipedia_logo_icon.webp';

  final FlightArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.xxs,
        vertical: DsSpacing.xxs,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(DsRadii.sm),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Image.asset(
            _wikipediaLogoIconAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  'W',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
