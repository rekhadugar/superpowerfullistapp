import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';
import '../engine/sort_mode_engine.dart';

class MainOptionsSheet extends StatelessWidget {
  const MainOptionsSheet({Key? key}) : super(key: key);

  Widget _buildGroupButton(BuildContext context, String label, SortMode mode, SortMode currentMode, ListProvider provider) {
    final isSelected = mode == currentMode;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        provider.setSortMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAction : theme.cardColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColors.primaryAction : theme.dividerColor,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.titleMedium?.color,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16.0,
        top: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2.0)
              ),
            ),
          ),

          // Search & Share Actions
          ListTile(
            leading: Icon(Icons.search_rounded, color: theme.textTheme.titleMedium?.color),
            title: Text('Search on the list', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement Search
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add_outlined, color: theme.textTheme.titleMedium?.color),
            title: Text('Share', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement Share
            },
          ),

          Divider(color: theme.dividerColor, height: 24.0, thickness: 1.0),

          // Grouping Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              'Group items by',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildGroupButton(context, 'Category', SortMode.categories, provider.currentSortMode, provider),
                _buildGroupButton(context, 'Store', SortMode.types, provider.currentSortMode, provider),
                _buildGroupButton(context, 'A-Z', SortMode.az, provider.currentSortMode, provider),
                _buildGroupButton(context, 'Custom Layout', SortMode.customFlat, provider.currentSortMode, provider),
              ],
            ),
          ),

          Divider(color: theme.dividerColor, height: 32.0, thickness: 1.0),

          // View & List Actions
          SwitchListTile(
            secondary: Icon(Icons.grid_view_rounded, color: theme.textTheme.titleMedium?.color),
            title: Text('Compact view', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            value: provider.isCompactView,
            activeColor: AppColors.primaryAction,
            onChanged: (val) {
              provider.toggleCompactView();
            },
          ),
          ListTile(
            leading: Icon(Icons.checklist_rounded, color: theme.textTheme.titleMedium?.color),
            title: Text('Check off all items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            onTap: () {
              provider.checkAllActiveItems();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.fact_check_outlined, color: theme.textTheme.titleMedium?.color),
            title: Text('View checked items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Archive Screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.destructiveAction),
            title: Text('Delete purchased items', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.destructiveAction, fontWeight: FontWeight.w600)),
            onTap: () {
              provider.deleteCompletedItems();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}