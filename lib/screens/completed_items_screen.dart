import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../widgets/list_item_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../widgets/section_header.dart';
import '../widgets/swipe_action_wrapper.dart';
import '../models/list_item.dart';
import '../engine/sticky_header_engine.dart';
import '../widgets/batch_action_bar.dart';
import '../widgets/fluid_edit_sheet.dart';

class CompletedItemsScreen extends StatefulWidget {
  const CompletedItemsScreen({Key? key}) : super(key: key);

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
    _toastTimer?.cancel(); // NEW: Prevent memory leaks
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

    // Reuse the exact same spatial cache engine, but map it to the checked off arrays
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

  // FIXED: Crash-proof SnackBar Helper
  void _showActionToast(BuildContext context, String message, List<String> undoIds) {
    final messenger = ScaffoldMessenger.of(context);

    _toastTimer?.cancel();
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryAction,
          onPressed: () => context.read<ListProvider>().restoreItems(undoIds),
        ),
      ),
    );

    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final displayList = listProvider.checkedDisplayList;
    final theme = Theme.of(context);
    final double safeBottomPadding = MediaQuery.of(context).padding.bottom;

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
                  // ListView.builder replaces ReorderableListView (Drag & Drop disabled)
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                        top: 0.0,
                        bottom: listProvider.isBatchModeActive ? 300 : safeBottomPadding + 100.0
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

                          // On the completed screen, clicking the checkbox immediately restores the item
                          onCheck: () {
                            final id = context.read<ListProvider>().toggleCompletion(item.id);
                            _showActionToast(context, '${item.title} restored', [id]);
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
                          isCompletedScreen: true, // Triggers Blue Restore aesthetics

                          onCheckout: () {
                            final id = context.read<ListProvider>().toggleCompletion(item.id);
                            _showActionToast(context, '${item.title} restored', [id]);
                          },
                          onEdit: () {
                            listProvider.clearAllInteractions();
                            listProvider.setEditItem(item.id);
                            listProvider.setFullEditRequest(true);
                          },
                          onDelete: () {
                            final id = context.read<ListProvider>().deleteItem(item.id);
                            _showActionToast(context, '${item.title} permanently deleted', [id]);
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

            // Pass true so the bar shows Restore instead of Move/Copy
            const BatchActionBar(isCompletedScreen: true),
          ],
        ),
      ),
    );
  }
}