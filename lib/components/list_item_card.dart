import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../theme/app_theme.dart';

class ListItemCard extends StatelessWidget {
  final ListItem item;

  const ListItemCard({required this.item, super.key});

  // Helper function to build the pills matching your screenshot
  Widget _buildPill(String text, {required bool isStore}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isStore ? AppTheme.primary : AppTheme.background, // Blue for store, grey for category
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStore) ...[
            const Icon(Icons.star, color: Colors.white, size: 10),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isStore ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('dismiss_${item.id}'),
        direction: DismissDirection.horizontal,

        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            context.read<ListProvider>().toggleItemStatus(item.id, item.isCompleted);
            return false;
          }
          return true;
        },

        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.check, color: Colors.white),
        ),

        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete, color: Colors.white),
        ),

        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            context.read<ListProvider>().deleteItem(item.id);
          }
        },

        child: Container(
          decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))
              ]
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Item Name on Top
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: item.isCompleted ? AppTheme.textSecondary : Colors.black,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 2. The Wrap automatically handles multiple locations overflowing to row 2
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Render a blue pill for every store in the array
                          ...item.locations.map((loc) => _buildPill(loc, isStore: true)),

                          // Render the grey category pill
                          if (item.category != 'Uncategorized')
                            _buildPill(item.category, isStore: false),

                          // Render the context/tag pill if it exists
                          if (item.context.isNotEmpty)
                            Text(
                                '• ${item.context}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. The Quantity Selector (Drag Handle Removed)
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        color: AppTheme.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36),
                        onPressed: () => context.read<ListProvider>().updateQuantity(item.id, item.quantity - 1),
                      ),
                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        color: Colors.black,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36),
                        onPressed: () => context.read<ListProvider>().updateQuantity(item.id, item.quantity + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}