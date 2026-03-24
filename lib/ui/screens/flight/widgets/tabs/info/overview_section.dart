import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/section_card.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({required this.overview, super.key});

  final String overview;

  @override
  Widget build(BuildContext context) {
    final content = overview.trim();
    return InfoSectionCard(
      title: 'Overview',
      child: content.isEmpty
          ? const _LoadingOverview()
          : Text(content, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _LoadingOverview extends StatelessWidget {
  const _LoadingOverview();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Expanded(child: Text('Building route overview...')),
      ],
    );
  }
}
