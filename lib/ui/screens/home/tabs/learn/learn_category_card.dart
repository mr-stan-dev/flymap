import 'package:flutter/material.dart';
import 'package:flymap/entity/learn_category.dart';
import 'package:flymap/i18n/strings.g.dart';

class LearnCategoryCard extends StatelessWidget {
  const LearnCategoryCard({
    required this.category,
    required this.onTap,
    super.key,
  });

  final LearnCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onImageColor = Colors.white.withValues(alpha: isDark ? 0.85 : 1.0);
    const textShadow = <Shadow>[
      Shadow(color: Color(0xCC000000), blurRadius: 6, offset: Offset(0, 1)),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 4 / 2,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  category.imageAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surfaceContainerHighest,
                            theme.colorScheme.surfaceContainer,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.school_outlined,
                          size: 42,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isDark)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black26),
                  ),
                ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: 0.62,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x00000000),
                            Color(0x73000000),
                            Color(0xBF000000),
                          ],
                          stops: [0, 0.68, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: onImageColor,
                        fontWeight: FontWeight.w800,
                        shadows: textShadow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 16,
                          color: onImageColor.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.t.learn.articlesCount(
                            count: category.articleCount,
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: onImageColor.withValues(alpha: 0.85),
                            shadows: textShadow,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
