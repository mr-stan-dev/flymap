import 'package:flutter/material.dart';

const double shareRouteCitiesChipWidth = 260;
const double shareRouteCitiesChipHeight = 58;

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.8),
            colorScheme.primary.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.82),
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
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
