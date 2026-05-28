import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/sticky_header_engine.dart';
import '../models/list_item.dart';
import '../providers/list_provider.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/batch_action_bar.dart';
import '../widgets/fluid_edit_sheet.dart';
import '../widgets/list_item_card.dart';
import '../widgets/section_header.dart';
import '../widgets/swipe_action_wrapper.dart';

class CompletedItemsScreen extends StatefulWidget {
  final bool isShoppingMode; // NEW: Context flag

  const CompletedItemsScreen({super.key, this.isShoppingMode = false});

  @override
  State<CompletedItemsScreen> createState() => _CompletedItemsScreenState();
}

class _CompletedItemsScreenState extends State<CompletedItemsScreen> {
  late ScrollController _scrollController;
  final ValueNotifier<PhantomHeaderData> _phantomHeaderState = ValueNotifier(const PhantomHeaderData());

  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _phantomHeaderState.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ListProvider>().clearAllInteractions();
      }
    });

    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<ListProvider>();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    final newHeaderData = StickyHeaderEngine.calculatePhantomHeader(
      _scrollController.offset,
      provider.checkedCumulativeYOffsets,
      provider.checkedDisplayList,
      textScaleFactor: textScale,
    );

    if (_phantomHeaderState.value.title != newHeaderData.title ||
        _phantomHeaderState.value.yOffset != newHeaderData.yOffset) {
      _phantomHeaderState.value = newHeaderData;
    }
  }

  // FIXED: Now accepts a dynamic onUndo callback to prevent unmounted context crashes
  void _showActionToast(BuildContext context, String message, VoidCallback? onUndo) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.fixed,
        backgroundColor: theme.colorScheme.inverseSurface,
        elevation: 0,
        content: SizedBox(
          height: 70.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold))),

                if (onUndo != null)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onUndo();
                    },
                    child: const Text('Undo', style: TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final theme = Theme.of(context);
    final double safeBottomPadding = MediaQuery.of(context).padding.bottom;

    // FIXED: Dynamically load the correct array based on context
    List<dynamic> displayList = widget.isShoppingMode
        ? ['Completed Shopping Items', ...listProvider.shoppingCompletedItems]
        : listProvider.checkedDisplayList;

    return GestureDetector(
      onTap: () {
        if (listProvider.openSwipeItemId.value != null) {
          listProvider.openSwipeItemId.value = null;
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.titleMedium?.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Completed Items',
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        body: Stack(
          children: [
            displayList.isEmpty
                ? Center(
              child: Text(
                'No completed items yet.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            )
                : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (listProvider.openSwipeItemId.value != null) {
                  listProvider.openSwipeItemId.value = null;
                }
                if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
                  if (listProvider.editItemId != null) {
                    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                    if (isKeyboardOpen) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    } else {
                      listProvider.setEditItem(null);
                    }
                  }
                }
                return false;
              },
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                        top: AppConstants.listTopPadding,
                        bottom: listProvider.isBatchModeActive
                            ? AppConstants.batchModeBottomClearance
                            : safeBottomPadding + AppConstants.listBottomClearance
                    ),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final item = displayList[index];

                      if (item is String) {
                        return Container(key: ValueKey('header_$item'), child: SectionHeader(title: item));
                      }

                      if (item is ListItem) {
                        Widget coreCard = ListItemCard(
                          title: item.title,
                          nWrap: item.nWrap,
                          nTagRows: item.nTagRows,
                          attributeRows: item.attributeRows,
                          type: item.type,
                          category: item.category,
                          sortMode: listProvider.currentSortMode,
                          quantity: item.quantity,
                          unit: item.unit,
                          isHighlighted: listProvider.flashItemId == item.id,
                          isDragging: false,
                          isBatchModeActive: listProvider.isBatchModeActive,
                          isBatchSelected: listProvider.selectedItemIds.contains(item.id),
                          isFluidEditing: listProvider.editItemId == item.id,

                          onCheck: () { // (And do the exact same for onCheckout below it)
                            if (widget.isShoppingMode) {
                              listProvider.restoreShoppingItems([item.id]);
                              _showActionToast(context, '${item.title} restored', () => listProvider.toggleShoppingItemsCompletion([item.id]));
                            } else {
                              final id = listProvider.toggleCompletion(item.id);
                              _showActionToast(context, '${item.title} restored', () => listProvider.toggleCompletion(id)); // Undo restore
                            }
                          },
                          onTap: () {
                            if (listProvider.openSwipeItemId.value != null) {
                              listProvider.openSwipeItemId.value = null;
                            } else {
                              if (listProvider.isBatchModeActive) {
                                context.read<ListProvider>().toggleSelection(item.id);
                              } else {
                                if (listProvider.editItemId == item.id) {
                                  context.read<ListProvider>().setEditItem(null);
                                } else {
                                  context.read<ListProvider>().setEditItem(item.id);
                                }
                              }
                            }
                          },
                          onToggleSelection: () => context.read<ListProvider>().toggleSelection(item.id),
                        );

                        return SwipeActionWrapper(
                          key: ValueKey('swipe_completed_${item.id}'),
                          itemId: item.id,
                          requireConfirm: true,
                          isBatchModeActive: listProvider.isBatchModeActive,
                          isCompletedScreen: true,

                          onCheckout: () {
                            if (widget.isShoppingMode) {
                              listProvider.restoreShoppingItems([item.id]);
                              _showActionToast(context, '${item.title} restored', () => listProvider.toggleShoppingItemsCompletion([item.id]));
                            } else {
                              final id = listProvider.toggleCompletion(item.id);
                              _showActionToast(context, '${item.title} restored', () => listProvider.toggleCompletion(id)); // Undo restore
                            }
                          },
                          onEdit: () {
                            listProvider.clearAllInteractions();
                            listProvider.setEditItem(item.id);
                            listProvider.setFullEditRequest(true);
                          },
                          onDelete: () {
                            if (widget.isShoppingMode) {
                              listProvider.deleteShoppingItemPermanently(item.id);
                              // FIXED: Now we can restore items permanently deleted from the completed screen!
                              _showActionToast(context, '${item.title} permanently deleted', () => listProvider.restoreDeletedShoppingItems([item.id]));
                            } else {
                              final id = listProvider.deleteItem(item.id);
                              _showActionToast(context, '${item.title} permanently deleted', () => listProvider.restoreItems([id]));
                            }
                          },
                          child: coreCard,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  ValueListenableBuilder<PhantomHeaderData>(
                    valueListenable: _phantomHeaderState,
                    builder: (context, data, child) {
                      if (data.title == null) return const SizedBox.shrink();
                      return Positioned(
                        top: 0, left: 0, right: 0,
                        child: RepaintBoundary(
                          child: Transform.translate(offset: Offset(0, data.yOffset), child: SectionHeader(title: data.title!)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const FluidEditSheet(),
            const BatchActionBar(isCompletedScreen: true),
          ],
        ),
      ),
    );
  }
}