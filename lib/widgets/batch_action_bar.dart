import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';

class BatchActionBar extends StatelessWidget {
  final bool isCompletedScreen; // NEW: Context awareness flag

  const BatchActionBar({
    Key? key,
    this.isCompletedScreen = false, // Default to false for the main screen
  }) : super(key: key);

  void _showTargetListSelector(BuildContext context, bool isCopy) {
    final provider = context.read<ListProvider>();
    final currentType = provider.currentListType;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCopy ? 'Copy to List...' : 'Move to List...',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Showing your other $currentType lists.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      final mockTargetListId = 'mock_list_id_$index';
                      return ListTile(
                        leading: const Icon(Icons.list_alt, color: AppColors.primaryAction),
                        title: Text('My Other Shopping List ${index + 1}'),
                        onTap: () {
                          if (isCopy) {
                            provider.copySelectedToTargetList(mockTargetListId);
                          } else {
                            provider.moveSelectedToTargetList(mockTargetListId);
                          }
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();
    final selectedCount = provider.selectedItemIds.length;

    final isVisible = selectedCount > 0;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: isVisible ? (safeBottom + 16.0) : -120.0,
      left: 16.0,
      right: 16.0,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(16.0),
        color: Colors.grey.shade900,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              // Deselect Button
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => provider.clearSelection(),
                tooltip: 'Clear Selection',
              ),

              // Count Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryAction,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '$selectedCount Selected',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),

              const Spacer(),

              // DYNAMIC ACTIONS BASED ON CONTEXT
              if (isCompletedScreen) ...[
                // Restore Button (Only on Completed Screen)
                TextButton.icon(
                  icon: const Icon(Icons.restore, color: Colors.white),
                  label: const Text('Restore', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    // Reusing checkSelectedItems because toggle logic pulls it back to active
                    provider.restoreItems(provider.selectedItemIds.toList());
                    provider.clearSelection();
                  },
                ),
              ] else ...[
                // Move Button (Only on Active Screen)
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline, color: Colors.white),
                  tooltip: 'Move',
                  onPressed: () => _showTargetListSelector(context, false),
                ),

                // Copy Button (Only on Active Screen)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  tooltip: 'Copy',
                  onPressed: () => _showTargetListSelector(context, true),
                ),
              ],

              // Delete Button (Available on both, but label changes conceptually)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                tooltip: 'Delete',
                onPressed: () => provider.deleteSelectedItems(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}