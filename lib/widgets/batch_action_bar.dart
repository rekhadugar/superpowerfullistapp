import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class BatchActionBar extends StatelessWidget {
  final bool isCompletedScreen;

  const BatchActionBar({
    Key? key,
    this.isCompletedScreen = false,
  }) : super(key: key);

  void _showTargetListSelector(BuildContext context, bool isCopy) {
    final provider = context.read<ListProvider>();
    final macroProvider = context.read<MacroListProvider>();
    final settings = context.read<SettingsProvider>();

    // ALIAS MAPPING: Dynamically fetch the current list type name
    final typeId = macroProvider.activeList?.typeId ?? 'sys_shopping';
    final currentTypeName = settings.getTypeById(typeId).name;

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
                  'Showing your other $currentTypeName lists.', // FIXED
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
                        title: Text('My Other $currentTypeName List ${index + 1}'), // FIXED
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
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => provider.clearSelection(),
                tooltip: 'Clear Selection',
              ),
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
              if (isCompletedScreen) ...[
                TextButton.icon(
                  icon: const Icon(Icons.restore, color: Colors.white),
                  label: const Text('Restore', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    provider.restoreItems(provider.selectedItemIds.toList());
                    provider.clearSelection();
                  },
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline, color: Colors.white),
                  tooltip: 'Move',
                  onPressed: () => _showTargetListSelector(context, false),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  tooltip: 'Copy',
                  onPressed: () => _showTargetListSelector(context, true),
                ),
              ],
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