import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/list_provider.dart';
import '../theme/app_theme.dart';

class MainOptionsSheet extends StatelessWidget {
  const MainOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          _buildOptionTile(
            context,
            icon: Icons.search,
            title: 'Search on the list',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildOptionTile(
            context,
            icon: Icons.person_add_alt,
            title: 'Share',
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const Divider(height: 16),

          // NEW: Interactive Group By Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('Group items by', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textSecondary)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildChoiceChip('Category', provider),
                const SizedBox(width: 8),
                _buildChoiceChip('Store', provider),
                const SizedBox(width: 8),
                _buildChoiceChip('List', provider),
                const SizedBox(width: 8),
                _buildChoiceChip('None', provider, label: 'Custom Layout'),
              ],
            ),
          ),

          const Divider(height: 16),

          _buildOptionTile(
            context,
            icon: Icons.checklist,
            title: 'Check off all items',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildOptionTile(
            context,
            icon: Icons.delete_outline,
            title: 'Delete purchased items',
            titleColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Helper widget to build the interactive chips
  Widget _buildChoiceChip(String value, ListProvider provider, {String? label}) {
    final isSelected = provider.groupBy == value;
    return ChoiceChip(
      label: Text(
          label ?? value,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87
          )
      ),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
      onSelected: (bool selected) {
        if (selected) {
          provider.setGroupBy(value);
        }
      },
    );
  }

  Widget _buildOptionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        Color? titleColor,
        Color? iconColor,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.black54, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: titleColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}