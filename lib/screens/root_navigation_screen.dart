import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:listicle_v2/screens/shopping_mode_screen.dart';
import 'package:provider/provider.dart';

import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
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

          if (index == 1) {
            final macroLists = context.read<MacroListProvider>().lists;
            context.read<ListProvider>().initializeShoppingMode(macroLists);
          }
        },
        behavior: HitTestBehavior.opaque,
        // FIXED (Batch 1.5): FittedBox acts as a safety valve to prevent RenderFlex errors on large scales
        child: FittedBox(
          fit: BoxFit.scaleDown,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    const double barHeight = 70.0;
    final bool showBottomNav = _isScrollVisible;

    return Scaffold(
      // FIXED: Prevents the Bottom Navigation Bar from floating above the keyboard
      resizeToAvoidBottomInset: false,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Layer 0: The Active Screen
          NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),

          // Layer 1: The Flush Auto-Hide Bottom Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: showBottomNav ? 0 : -(barHeight + safeBottom + 20),
            height: barHeight + safeBottom,
            child: Container(
              padding: EdgeInsets.only(bottom: safeBottom),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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