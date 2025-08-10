import 'package:flutter/material.dart';

class PinnedTabBarHeader extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  PinnedTabBarHeader({required this.tabBar, required this.backgroundColor});

  @override
  double get minExtent => kTextTabBarHeight;

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant PinnedTabBarHeader oldDelegate) => false;
}
