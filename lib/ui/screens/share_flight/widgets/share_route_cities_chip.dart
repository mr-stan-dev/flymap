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
    return Container(
      width: shareRouteCitiesChipWidth,
      height: shareRouteCitiesChipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF12212D).withValues(alpha: 0.88),
            const Color(0xFF16384A).withValues(alpha: 0.86),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.78),
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
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
