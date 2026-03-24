import 'package:flutter/material.dart';

class InfoSectionCard extends StatelessWidget {
  const InfoSectionCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    super.key,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(title),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }
}
