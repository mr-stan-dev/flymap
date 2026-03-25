import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

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
    return ExpandableSectionCard(
      title: title,
      initiallyExpanded: initiallyExpanded,
      child: child,
    );
  }
}
