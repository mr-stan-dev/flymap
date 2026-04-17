import 'package:flutter/material.dart';

class SafeBottomSheet extends StatelessWidget {
  const SafeBottomSheet({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final bottomSafe = media.viewPadding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset + bottomSafe),
      child: Padding(padding: padding, child: child),
    );
  }
}
