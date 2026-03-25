import 'package:flutter/material.dart';

const double shareRouteCitiesChipWidth = 260;
const double shareRouteCitiesChipHeight = 56;

class ShareRouteCitiesChip extends StatelessWidget {
  const ShareRouteCitiesChip({
    required this.fromCity,
    required this.toCity,
    required this.fromCode,
    required this.toCode,
    super.key,
  });

  final String fromCity;
  final String toCity;
  final String fromCode;
  final String toCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: shareRouteCitiesChipWidth,
      height: shareRouteCitiesChipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiaryContainer.withValues(alpha: 0.9),
            colorScheme.tertiary.withValues(alpha: 0.84),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onTertiary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onTertiary.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$fromCity ($fromCode)  ->  $toCity ($toCode)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
