import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:listicle_v2/screens/shopping_mode_screen.dart';
import 'package:provider/provider.dart';

import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../theme/app_theme.dart';
import 'global_settings_screen.dart';
import 'main_screen.dart';

class RootNavigationScreen extends StatefulWidget {
  const RootNavigationScreen({super.key});

  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen> {
  int _currentIndex = 0;
  bool _isScrollVisible = true;

  final List<Widget> _screens = [
    const MainScreen(),
    const ShoppingModeScreen(),
    const GlobalSettingsScreen(),
  ];

  bool _handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.forward) {
        if (!_isScrollVisible) setState(() => _isScrollVisible = true);
      } else if (notification.direction == ScrollDirection.reverse) {
        if (_isScrollVisible) setState(() => _isScrollVisible = false);
      }
    }
    return false;
  }

  Widget _buildNavItem(IconData icon, String label, int index, ThemeData theme) {
    final isSelected = _currentIndex == index;
    final unselectedColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ?? Colors.grey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);

          // FIXED: Trigger the cross-list fetch ONLY when they actually tap the tab.
          // This guarantees MacroLists are loaded, and prevents stale data.
          if (index == 1) {
            final macroLists = context.read<MacroListProvider>().lists;
            context.read<ListProvider>().initializeShoppingMode(macroLists);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryAction : unselectedColor, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryAction : unselectedColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();

    // UX ENGINE: Automatically yield the space to contextual menus
    final isBatchActive = provider.selectedItemIds.isNotEmpty;
    final isEditingActive = provider.editItemId != null || provider.isFullEditRequested;
    final showBottomNav = _isScrollVisible && !isBatchActive && !isEditingActive;

    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomOffset = safeBottom > 0 ? safeBottom : 16.0;
    const barHeight = 70.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // LAYER 0: The App Content
          NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),

          // LAYER 1: The Floating Auto-Hide Bar
          // LAYER 1: The Floating Auto-Hide Bar
          // LAYER 1: The Flush Auto-Hide Bottom Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 0,  // FIXED: Full width
            right: 0, // FIXED: Full width
            bottom: showBottomNav ? 0 : -(barHeight + safeBottom + 20), // FIXED: Flush to bottom
            height: barHeight + safeBottom, // FIXED: Absorbs the home indicator area
            child: Container(
              padding: EdgeInsets.only(bottom: safeBottom), // Pushes icons up above the home indicator
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), // Subtle shadow above the bar
                      blurRadius: 10,
                      offset: const Offset(0, -2)
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.format_list_bulleted_rounded, 'Lists', 0, Theme.of(context)),
                  _buildNavItem(Icons.storefront_rounded, 'Shop Mode', 1, Theme.of(context)),
                  _buildNavItem(Icons.person_outline_rounded, 'Profile', 2, Theme.of(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}