import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW: For Profile Data

import '../providers/macro_list_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/create_list_screen.dart';
import '../screens/global_settings_screen.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isBottomBarVisible = true;

  bool _handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.forward) {
        if (!_isBottomBarVisible) setState(() => _isBottomBarVisible = true);
      } else if (notification.direction == ScrollDirection.reverse) {
        if (_isBottomBarVisible) setState(() => _isBottomBarVisible = false);
      }
    }
    return false;
  }

  // Location: lib/widgets/app_drawer.dart
// (Keep all your existing imports and state logic)

  @override
  Widget build(BuildContext context) {
    // ... (Keep existing variable setup: provider, settings, lists, activeId, theme, geometry) ...
    final provider = context.watch<MacroListProvider>();
    final settings = context.watch<SettingsProvider>();

    final lists = provider.lists;
    final activeId = provider.activeListId;

    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final geometry = FluidGeometry(textScale);

    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomBarHeight = 70.0 + safeBottom;

    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Listicle User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final photoUrl = user?.photoURL;

    // Calculate heights for the reachability math
    final double expandedHeight = MediaQuery.of(context).size.height * 0.33;
    final double collapsedHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
    // FIXED: Calculate the exact distance the header needs to travel to collapse
    final double collapseTravelDistance = expandedHeight - collapsedHeight;

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // --- THE ONE UI COLLAPSING PROFILE HEADER ---
                SliverAppBar(
                  expandedHeight: expandedHeight,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final currentHeight = constraints.biggest.height;
                      double expandRatio = (currentHeight - collapsedHeight) / collapseTravelDistance;
                      expandRatio = expandRatio.clamp(0.0, 1.0);

                      return FlexibleSpaceBar(
                        centerTitle: true,
                        titlePadding: const EdgeInsets.only(bottom: 16.0),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            color: theme.textTheme.titleMedium?.color,
                            fontSize: 16 + (expandRatio * 4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        background: Align(
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: expandRatio,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 40.0),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: AppColors.primaryAction.withValues(alpha: 0.1),
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                child: photoUrl == null
                                    ? Text(initial, style: const TextStyle(fontSize: 36, color: AppColors.primaryAction, fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: Divider(height: 1)),

                // --- FIXED: STICKY TAXONOMY SLIVERS ---
                ...settings.allTypes.expand((type) {
                  final typeLists = lists.where((l) => l.typeId == type.id).toList();
                  if (typeLists.isEmpty) return <Widget>[];

                  return [
                    // 1. The Sticky Master List Header
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _MasterListHeaderDelegate(
                        title: type.name,
                        iconCodePoint: type.iconCodePoint,
                        geometry: geometry,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        textColor: AppColors.primaryAction.withValues(alpha: 0.8),
                      ),
                    ),

                    // 2. The List Items under the header
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final list = typeLists[index];
                          final isSelected = list.id == activeId;

                          return InkWell(
                            onTap: () {
                              provider.setActiveList(list.id);
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: double.infinity,
                              color: isSelected ? AppColors.primaryAction.withValues(alpha: 0.1) : Colors.transparent,
                              padding: EdgeInsets.only(
                                left: geometry.horizontalPadding + geometry.iconSize + geometry.interElementGap,
                                right: geometry.horizontalPadding,
                                top: 14.0,
                                bottom: 14.0,
                              ),
                              child: Text(
                                list.name,
                                style: TextStyle(
                                  fontSize: AppConstants.titleFontSize,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primaryAction : theme.textTheme.titleMedium?.color,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: typeLists.length,
                      ),
                    ),
                  ];
                }),

                // --- FIXED: REACHABILITY SPACER ---
                // Appends exact blank space needed to guarantee the One UI profile header can always be collapsed
                SliverToBoxAdapter(
                  child: SizedBox(height: bottomBarHeight + collapseTravelDistance + 20),
                ),
              ],
            ),
          ),

          // Layer 1: Auto-Hiding Drawer Bottom Bar
          // ... (Keep existing AnimatedPositioned block exactly the same) ...
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _isBottomBarVisible ? 0 : -bottomBarHeight,
            height: bottomBarHeight,
            child: Container(
              padding: EdgeInsets.only(bottom: safeBottom),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSettingsScreen()));
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings_outlined, size: geometry.iconSize, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(height: 4),
                          Text('Settings', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListScreen()));
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, size: geometry.iconSize, color: AppColors.primaryAction),
                          const SizedBox(height: 4),
                          const Text('New List', style: TextStyle(fontSize: 10, color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW: Custom Delegate for Sticky Taxonomy Headers ---
class _MasterListHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final int iconCodePoint;
  final FluidGeometry geometry;
  final Color backgroundColor;
  final Color textColor;

  _MasterListHeaderDelegate({
    required this.title,
    required this.iconCodePoint,
    required this.geometry,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Solid background prevents lists from showing through the header when scrolling
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.fromLTRB(geometry.horizontalPadding, 24.0, geometry.horizontalPadding, 8.0),
      alignment: Alignment.bottomLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
            size: geometry.iconSize,
            color: textColor,
          ),
          SizedBox(width: geometry.interElementGap),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: AppConstants.headerFontSize, // Automatically scaled by textScaler
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1.2,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mathematically calculate the required height based on fluid scaling
  @override
  double get maxExtent => 24.0 + (geometry.iconSize > AppConstants.headerFontSize ? geometry.iconSize : AppConstants.headerFontSize) + 8.0;
  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _MasterListHeaderDelegate oldDelegate) {
    return title != oldDelegate.title || geometry.scale != oldDelegate.geometry.scale;
  }
}