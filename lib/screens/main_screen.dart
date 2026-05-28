// Location: lib/screens/main_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/sticky_header_engine.dart';
import '../models/list_item.dart';
import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/batch_action_bar.dart';
import '../widgets/edit_item_bottom_sheet.dart';
import '../widgets/fluid_edit_sheet.dart';
import '../widgets/list_item_card.dart';
import '../widgets/main_options_sheet.dart';
import '../widgets/section_header.dart';
import '../widgets/swipe_action_wrapper.dart';
import 'completed_items_screen.dart'; // NEW IMPORT
import 'create_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late ScrollController _scrollController;
  final ValueNotifier<PhantomHeaderData> _phantomHeaderState = ValueNotifier(const PhantomHeaderData());

  String? _lastScrolledFlashId;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ListProvider>().addListener(_onProviderStateChanged);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ListProvider>().updateViewportMetrics(screenWidth, textScale);
      }
    });
  }

  void _onProviderStateChanged() {
    if (!mounted) return;
    final provider = context.read<ListProvider>();

    if (provider.flashItemId != null && provider.flashItemId != _lastScrolledFlashId) {
      _lastScrolledFlashId = provider.flashItemId;
      final targetOffset = provider.getOffsetForItem(provider.flashItemId!);

      if (targetOffset != null && _scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double safeBuffer = AppConstants.headerHeight;
        double scrollTarget = (targetOffset - safeBuffer).clamp(0.0, maxScroll);

        _scrollController.animateTo(
          scrollTarget,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    } else if (provider.flashItemId == null) {
      _lastScrolledFlashId = null;
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel(); // NEW: Prevent memory leaks
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _phantomHeaderState.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<ListProvider>();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    final newHeaderData = StickyHeaderEngine.calculatePhantomHeader(
      _scrollController.offset,
      provider.cumulativeYOffsets,
      provider.displayList,
      textScaleFactor: textScale,
    );

    if (_phantomHeaderState.value.title != newHeaderData.title ||
        _phantomHeaderState.value.yOffset != newHeaderData.yOffset) {
      _phantomHeaderState.value = newHeaderData;
    }
  }

  // FIXED: Auto-dodging SnackBar Helper
  // FIXED: Flush Geometry Masking SnackBar with Auto-Contrast
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
    final macroProvider = context.watch<MacroListProvider>();

    if (!macroProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (macroProvider.lists.isEmpty) {
      return const CreateListScreen(isFirstLaunch: true);
    }

    final activeId = macroProvider.activeListId!;
    // FIXED: Renamed to match the exact method signature in list_provider.dart
    context.read<ListProvider>().loadItems(activeId);

    context.read<ListProvider>().syncGlobalDictionary(macroProvider.lists);

    final listProvider = context.watch<ListProvider>();
    final displayList = listProvider.displayList;
    final activeList = context.watch<MacroListProvider>().activeList;
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
        drawer: const AppDrawer(),
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leadingWidth: AppConstants.horizontalPadding + AppConstants.leadingBlockWidth + AppConstants.interElementGap,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppConstants.horizontalPadding),
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu_rounded, color: theme.textTheme.titleMedium?.color),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          titleSpacing: 0,
          title: Text(activeList?.name ?? 'Listicle'),
          backgroundColor: theme.cardColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: theme.textTheme.titleMedium?.color),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const MainOptionsSheet(),
                );
              },
            ),
          ],
        ),

        body: Stack(
          children: [
            displayList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All caught up!\nTap + to add your first item.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (listProvider.checkedDisplayList.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedItemsScreen())),
                      icon: Icon(Icons.history_rounded, color: theme.textTheme.bodyMedium?.color),
                      label: Text('View Completed Items', style: theme.textTheme.bodyMedium),
                    ),
                  ]
                ],
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
                  ReorderableListView.builder(
                    scrollController: _scrollController,
                    padding: EdgeInsets.only(
                        top: AppConstants.listTopPadding,
                        bottom: listProvider.isBatchModeActive
                            ? AppConstants.batchModeBottomClearance
                            : safeBottomPadding + AppConstants.listBottomClearance
                    ),
                    itemCount: displayList.length,
                    buildDefaultDragHandles: false,

                    footer: Padding(
                      key: const ValueKey('completed_footer'),
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedItemsScreen())),
                        icon: Icon(Icons.history_rounded, color: theme.textTheme.bodyMedium?.color),
                        label: Text('View Completed Items', style: theme.textTheme.bodyMedium),
                      ),
                    ),

                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex == newIndex) {
                        final item = displayList[oldIndex];
                        if (item is ListItem) context.read<ListProvider>().toggleSelection(item.id);
                        return;
                      }
                      context.read<ListProvider>().executeNativeReorder(oldIndex, newIndex);
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(color: Colors.transparent, elevation: 8.0, shadowColor: Colors.black45, child: child);
                    },
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

                          onCheck: () {
                            final id = listProvider.toggleCompletion(item.id);
                            // FIXED: Uses the top-level listProvider reference, preventing the crash
                            _showActionToast(context, '${item.title} checked off', () => listProvider.restoreItems([id]));
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

                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('drag_${item.id}'),
                          index: index,
                          child: SwipeActionWrapper(
                            key: ValueKey('swipe_${item.id}'),
                            itemId: item.id,
                            requireConfirm: true,
                            isBatchModeActive: listProvider.isBatchModeActive,
                            onCheckout: () {
                              final id = listProvider.toggleCompletion(item.id);
                              // FIXED: Uses the top-level listProvider reference, preventing the crash
                              _showActionToast(context, '${item.title} checked off', () => listProvider.restoreItems([id]));
                            },
                            onEdit: () {
                              listProvider.clearAllInteractions();
                              listProvider.setEditItem(item.id);
                              listProvider.setFullEditRequest(true);
                            },
                            onDelete: () {
                              final id = listProvider.deleteItem(item.id);
                              // FIXED: Safely restores item without relying on the destroyed list item context
                              _showActionToast(context, '${item.title} deleted', () => listProvider.restoreItems([id]));
                            },
                            child: coreCard,
                          ),
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
            const BatchActionBar(),

            // NEW: AnimatedPositioned FAB placed inside the Stack to avoid Scaffold conflicts
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              right: 16.0,
              bottom: (listProvider.isBatchModeActive || listProvider.editItemId != null)
                  ? -100.0 // Slides off screen during batch/edit mode
                  : safeBottomPadding + AppConstants.listBottomClearance + 16.0, // Safely floats above the bottom bar
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => EditItemBottomSheet(
                      onSave: (title, attributes, type, category, quantity, unit) {
                        context.read<ListProvider>().addItem(
                          title, attributes, type, category, quantity, unit,
                        );
                      },
                    ),
                  );
                },
                backgroundColor: AppColors.primaryAction,
                elevation: 4,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}