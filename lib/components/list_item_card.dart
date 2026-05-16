import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../theme/app_theme.dart';

class ListItemCard extends StatelessWidget {
  final ListItem item;

  const ListItemCard({required this.item, super.key});

  // Utility to dynamically color the badge based on category
  Color _getStoreColor(String category) {
    switch (category.toLowerCase()) {
      case 'groceries': return Colors.orange;
      case 'hardware': return Colors.blueGrey;
      case 'pharmacy': return Colors.redAccent;
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
      direction: DismissDirection.horizontal,

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          context.read<ListProvider>().toggleItemStatus(item.id, item.isCompleted);
          return false; // Bounce back for completion
        } else {
          return true; // Let it slide off for deletion
        }
      },

      background: Container(
        color: AppTheme.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),

      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<ListProvider>().deleteItem(item.id);
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), // Fixed deprecation warning
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStoreColor(item.category).withValues(alpha: 0.15), // Fixed deprecation warning
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _getStoreColor(item.category),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: item.isCompleted ? AppTheme.textSecondary : Colors.black,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
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
                          onPressed: () {
                            context.read<ListProvider>().updateQuantity(item.id, item.quantity - 1);
                          },
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          color: Colors.black,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36),
                          onPressed: () {
                            context.read<ListProvider>().updateQuantity(item.id, item.quantity + 1);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.drag_handle, color: AppTheme.textSecondary, size: 28),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}