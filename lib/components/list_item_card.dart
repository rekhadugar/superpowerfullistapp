import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../theme/app_theme.dart';
import 'item_form_modal.dart';

// 1. Upgraded to a StatefulWidget to handle our custom shrink animation
class ListItemCard extends StatefulWidget {
  final ListItem item;

  const ListItemCard({required this.item, super.key});

  @override
  State<ListItemCard> createState() => _ListItemCardState();
}

class _ListItemCardState extends State<ListItemCard> {
  // The trigger for our smooth collapse
  bool _isShrinking = false;

  // This handles the animation timing and database removal safely
  void _shrinkAndRemove(bool isDelete) {
    setState(() {
      _isShrinking = true;
    });

    // Wait for the AnimatedSize to finish closing before nuking the data
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        if (isDelete) {
          context.read<ListProvider>().deleteItem(widget.item.id);
        } else {
          context.read<ListProvider>().toggleItemStatus(widget.item.id, widget.item.isCompleted);
        }
      }
    });
  }

  Widget _buildPill(String text, {required bool isStore}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isStore ? AppTheme.primary : AppTheme.background,
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
    // 2. Wrap the entire card in AnimatedSize
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // When shrinking is triggered, it folds down to a height of 0
      child: _isShrinking
          ? const SizedBox(width: double.infinity, height: 0)
          : Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Slidable(
          key: ValueKey('slidable_${widget.item.id}'),

          // 3. LEFT SWIPE (Complete)
          startActionPane: ActionPane(
            motion: const StretchMotion(),
            dismissible: DismissiblePane(
              onDismissed: () {},
              // confirmDismiss intercepts the library's buggy teardown
              confirmDismiss: () async {
                _shrinkAndRemove(false); // Trigger our custom animation
                return false; // Prevent Slidable from crashing the list
              },
            ),
            children: [
              SlidableAction(
                onPressed: (context) => _shrinkAndRemove(false),
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                icon: Icons.check,
                label: 'Complete',
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),

          // 4. RIGHT SWIPE (Edit/Delete)
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.6,
            dismissible: DismissiblePane(
              onDismissed: () {},
              confirmDismiss: () async {
                _shrinkAndRemove(true); // Safely animate deletion
                return false;
              },
            ),
            children: [
              SlidableAction(
                flex: 2,
                onPressed: (context) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    // Notice how we pass the item to trigger Edit Mode!
                    builder: (context) => ItemFormModal(
                      activeListType: context.read<ListProvider>().activeType,
                      existingItem: widget.item,
                    ),
                  );
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Tap to Edit',
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)
                ),
              ),
              SlidableAction(
                flex: 1,
                onPressed: (context) => _shrinkAndRemove(true),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12), bottomRight: Radius.circular(12)
                ),
              ),
            ],
          ),

          // 5. The actual Card UI
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
                        Text(
                          widget.item.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: widget.item.isCompleted ? AppTheme.textSecondary : Colors.black,
                            decoration: widget.item.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...widget.item.locations.map((loc) => _buildPill(loc, isStore: true)),
                            if (widget.item.category != 'Uncategorized')
                              _buildPill(widget.item.category, isStore: false),
                            if (widget.item.context.isNotEmpty)
                              Text(
                                  '• ${widget.item.context}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

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
                          onPressed: () => context.read<ListProvider>().updateQuantity(widget.item.id, widget.item.quantity - 1),
                        ),
                        Text('${widget.item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          color: Colors.black,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36),
                          onPressed: () => context.read<ListProvider>().updateQuantity(widget.item.id, widget.item.quantity + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}