import 'package:flutter/material.dart';

/// Pins a TabBar as a sliver header, for profile-style screens where a
/// scrollable header sits above a sticky TabBar (see NestedScrollView).
class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}
