import 'package:flutter/material.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';

class LearnArticleTile extends StatelessWidget {
  const LearnArticleTile({
    required this.article,
    required this.locked,
    required this.isSeen,
    required this.isFavorite,
    required this.favoriteInFlight,
    required this.onFavoriteTap,
    required this.onTap,
    super.key,
  });

  final LearnArticleMeta article;
  final bool locked;
  final bool isSeen;
  final bool isFavorite;
  final bool favoriteInFlight;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: favoriteInFlight ? null : onFavoriteTap,
        alignment: Alignment.center,
        icon: favoriteInFlight
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFavorite
                    ? DsSemanticColors.warning(context)
                    : theme.colorScheme.onSurfaceVariant,
              ),
      ),
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locked) ...[
            const ProBadge(
              compact: true,
              variant: ProBadgeVariant.premiumBlueStripes,
            ),
            const SizedBox(width: 4),
          ] else ...[
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 2),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
