import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import 'item_form_modal.dart';

class ListItemCard extends StatefulWidget {
  final ListItem item;
  final bool isCompact;
  final bool isDraggingProxy;
  final ValueChanged<double>? onPointerDown;

  const ListItemCard({
    required this.item,
    this.isCompact = false,
    this.isDraggingProxy = false,
    this.onPointerDown,
    super.key
  });

  @override
  State<ListItemCard> createState() => _ListItemCardState();
}

class _ListItemCardState extends State<ListItemCard> {
  bool _isShrinking = false;

  void _shrinkAndRemove(bool isDelete) {
    setState(() {
      _isShrinking = true;
    });

    final item = widget.item;
    final bool wasCompleted = item.isCompleted;
    final provider = context.read<ListProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // FIXED: Deletion dispatch perfectly syncs with the new global layout duration
    Future.delayed(AppConstants.layoutDuration, () {
      if (isDelete) {
        provider.deleteItem(item.id);
      } else {
        provider.toggleItemStatus(item.id, wasCompleted);
      }

      scaffoldMessenger.clearSnackBars();

      final actionText = isDelete ? 'Deleted' : (wasCompleted ? 'Unchecked' : 'Checked');

      final controller = scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            '$actionText: "${item.name}"',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppTheme.primary,
            onPressed: () {
              if (isDelete) {
                provider.restoreItem(item.id);
              } else {
                provider.toggleItemStatus(item.id, !wasCompleted);
              }
              scaffoldMessenger.hideCurrentSnackBar();
            },
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 5), () {
        try { controller.close(); } catch (_) {}
      });
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

  void _handleInteraction() {
    if (widget.isCompact) {
      context.read<ListProvider>().toggleExpandedItem(widget.item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListProvider>();
    final isLocallyExpanded = !widget.isDraggingProxy && provider.expandedItemId == widget.item.id;
    final isActuallyCompact = widget.isCompact && !isLocallyExpanded;

    return Listener(
      onPointerDown: (event) {
        widget.onPointerDown?.call(event.localPosition.dy);
      },
      child: AnimatedSize(
        // FIXED: Shifted to global modular parameters
        duration: AppConstants.layoutDuration,
        curve: AppConstants.layoutCurve,
        alignment: Alignment.topCenter,
        child: _isShrinking
            ? const SizedBox(width: double.infinity, height: 0)
            : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Slidable(
            key: ValueKey('slidable_${widget.item.id}'),

            startActionPane: ActionPane(
              motion: const StretchMotion(),
              dismissible: DismissiblePane(
                onDismissed: () {},
                confirmDismiss: () async {
                  _shrinkAndRemove(false);
                  return false;
                },
              ),
              children: [
                SlidableAction(
                  onPressed: (context) => _shrinkAndRemove(false),
                  backgroundColor: widget.item.isCompleted ? Colors.orange : AppTheme.success,
                  foregroundColor: Colors.white,
                  icon: widget.item.isCompleted ? Icons.restore : Icons.check,
                  label: widget.item.isCompleted ? 'Uncheck' : 'Complete',
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),

            endActionPane: ActionPane(
              motion: const StretchMotion(),
              extentRatio: 0.6,
              dismissible: DismissiblePane(
                onDismissed: () {},
                confirmDismiss: () async {
                  _shrinkAndRemove(true);
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

            child: GestureDetector(
              onTap: _handleInteraction,
              child: Container(
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      if (!widget.isDraggingProxy)
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))
                      else
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8))
                    ]
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: isActuallyCompact ? 12.0 : 16.0
                  ),
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

                            if (!isActuallyCompact && (widget.item.locations.isNotEmpty || widget.item.category != 'Uncategorized' || widget.item.context.isNotEmpty)) ...[
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
                            ]
                          ],
                        ),
                      ),

                      if (isActuallyCompact && widget.item.quantity > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 36),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${widget.item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                widget.item.unit,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 14),
                              ),
                            ),
                          ],
                        )
                      else if (!isActuallyCompact)
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 36, height: 36,
                                child: IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  color: AppTheme.textSecondary,
                                  padding: EdgeInsets.zero,
                                  splashRadius: 18,
                                  onPressed: () => context.read<ListProvider>().updateQuantity(widget.item.id, widget.item.quantity - 1),
                                ),
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                    '${widget.item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
                                ),
                              ),
                              SizedBox(
                                width: 36, height: 36,
                                child: IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  color: Colors.black,
                                  padding: EdgeInsets.zero,
                                  splashRadius: 18,
                                  onPressed: () => context.read<ListProvider>().updateQuantity(widget.item.id, widget.item.quantity + 1),
                                ),
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
        ),
      ),
    );
  }
}