import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import 'item_form_modal.dart';

// Location: lib/components/list_item_card.dart

class ListItemCard extends StatefulWidget {
  final ListItem item;
  final bool isCompact;
  final bool isDraggingProxy;
  final bool isExpanded;
  final ValueChanged<double>? onPointerDown;

  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onUpdateQuantity;
  final VoidCallback onEdit;

  const ListItemCard({
    required this.item,
    this.isCompact = false,
    this.isDraggingProxy = false,
    this.isExpanded = false,
    this.onPointerDown,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onRestore,
    required this.onToggleExpand,
    required this.onUpdateQuantity,
    required this.onEdit,
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Future.delayed(AppConstants.layoutDuration, () {
      if (isDelete) {
        widget.onDelete();
      } else {
        widget.onToggleStatus();
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
                widget.onRestore();
              } else {
                widget.onToggleStatus();
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
      widget.onToggleExpand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocallyExpanded = !widget.isDraggingProxy && widget.isExpanded;
    final isActuallyCompact = widget.isCompact && !isLocallyExpanded;
    final hasExtraDetails = widget.item.locations.isNotEmpty || widget.item.category != 'Uncategorized' || widget.item.context.isNotEmpty;

    return Listener(
      onPointerDown: (event) {
        widget.onPointerDown?.call(event.localPosition.dy);
      },
      child: AnimatedSize(
        duration: AppConstants.layoutDuration,
        curve: AppConstants.layoutCurve,
        alignment: Alignment.topCenter,
        child: _isShrinking
            ? const SizedBox(width: double.infinity, height: 0)
            : Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.padCompact),
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
                  borderRadius: AppConstants.cardRadius,
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
                  onPressed: (context) => widget.onEdit(),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'Tap to Edit',
                  borderRadius: BorderRadius.only(
                      topLeft: AppConstants.cardRadius.topLeft,
                      bottomLeft: AppConstants.cardRadius.bottomLeft
                  ),
                ),
                SlidableAction(
                  flex: 1,
                  onPressed: (context) => _shrinkAndRemove(true),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  borderRadius: BorderRadius.only(
                      topRight: AppConstants.cardRadius.topRight,
                      bottomRight: AppConstants.cardRadius.bottomRight
                  ),
                ),
              ],
            ),

            child: GestureDetector(
              onTap: _handleInteraction,
              child: Container(
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: AppConstants.cardRadius,
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      if (!widget.isDraggingProxy)
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))
                      else
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8))
                    ]
                ),
                child: AnimatedSize(
                  duration: AppConstants.layoutDuration,
                  curve: AppConstants.layoutCurve,
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppConstants.padMedium,
                      right: AppConstants.padMedium,
                      top: AppConstants.padMedium,
                      bottom: isActuallyCompact ? AppConstants.padCompact : AppConstants.padMedium,
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
                                // CHANGED: Reduced font size from 18 to 16
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: widget.item.isCompleted ? AppTheme.textSecondary : Colors.black,
                                  decoration: widget.item.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),

                              AnimatedSize(
                                duration: AppConstants.layoutDuration,
                                curve: AppConstants.layoutCurve,
                                alignment: Alignment.topCenter,
                                child: (!isActuallyCompact && hasExtraDetails)
                                    ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: AppConstants.padSmall),
                                    Wrap(
                                      spacing: AppConstants.padTiny,
                                      runSpacing: AppConstants.padTiny,
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
                                )
                                    : const SizedBox(width: double.infinity, height: 0),
                              ),
                            ],
                          ),
                        ),

                        AnimatedCrossFade(
                          duration: AppConstants.layoutDuration,
                          firstCurve: AppConstants.layoutCurve,
                          secondCurve: AppConstants.layoutCurve,
                          sizeCurve: AppConstants.layoutCurve,
                          crossFadeState: isActuallyCompact ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          alignment: Alignment.center,
                          firstChild: widget.item.quantity > 0
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 36),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${widget.item.quantity}',
                                  textAlign: TextAlign.center,
                                  // Quantity font size is 16 (matches item name)
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  widget.item.unit,
                                  textAlign: TextAlign.center,
                                  // CHANGED: Increased unit font size from 14 to 16 to match item name
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 16),
                                ),
                              ),
                            ],
                          )
                              : const SizedBox(width: 100, height: 36),
                          secondChild: Container(
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
                                    onPressed: () => widget.onUpdateQuantity(widget.item.quantity - 1),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                      '${widget.item.quantity}',
                                      textAlign: TextAlign.center,
                                      // Quantity font size is 16
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
                                    onPressed: () => widget.onUpdateQuantity(widget.item.quantity + 1),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}