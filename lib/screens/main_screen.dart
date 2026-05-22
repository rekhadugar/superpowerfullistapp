// Location: lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../widgets/edit_item_bottom_sheet.dart';
import '../widgets/fluid_edit_sheet.dart';
import '../widgets/list_item_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../widgets/section_header.dart';
import '../widgets/swipe_action_wrapper.dart';
import '../models/list_item.dart';
import '../engine/sticky_header_engine.dart'; // IMPORT THE ENGINE
import '../engine/sort_mode_engine.dart'; // IMPORT THE SORT ENGINE
import '../providers/macro_list_provider.dart'; // <--- NEW
import '../widgets/app_drawer.dart';
import 'create_list_screen.dart'; // <--- NEW

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late ScrollController _scrollController;
  final ValueNotifier<PhantomHeaderData> _phantomHeaderState = ValueNotifier(const PhantomHeaderData());

  String? _lastScrolledFlashId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Safely attach a listener to execute scroll side-effects outside the build phase
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
    final textScale = MediaQuery.textScalerOf(context).scale(1.0); // Fetch Scale

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ListProvider>().updateViewportMetrics(screenWidth, textScale);
      }
    });
  }

  void _onProviderStateChanged() {
    if (!mounted) return;
    final provider = context.read<ListProvider>();

    // Only scroll if there is a new item we haven't scrolled to yet
    if (provider.flashItemId != null && provider.flashItemId != _lastScrolledFlashId) {
      _lastScrolledFlashId = provider.flashItemId;
      final targetOffset = provider.getOffsetForItem(provider.flashItemId!);

      if (targetOffset != null && _scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;

        // Include ONLY the 44px sticky header height for a perfect mathematical snap
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _phantomHeaderState.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<ListProvider>();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0); // Fetch Scale

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

  @override
  Widget build(BuildContext context) {
    final macroProvider = context.watch<MacroListProvider>();

    // 1. Loading State
    if (!macroProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. The True Blank Slate Override (Forces Create List)
    if (macroProvider.lists.isEmpty) {
      return const CreateListScreen(isFirstLaunch: true);
    }

    // 3. Trigger Data Query for the Active List
    final activeId = macroProvider.activeListId!;
    // Safe to call in build() because loadItemsForList returns early if already loaded
    context.read<ListProvider>().loadItemsForList(activeId);

    final listProvider = context.watch<ListProvider>();
    final displayList = listProvider.displayList;
    final activeList = context.watch<MacroListProvider>().activeList;
    final theme = Theme.of(context);
    final double safeBottomPadding = MediaQuery.of(context).padding.bottom;

    // Remove focus if tapping the background list
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
            child: Builder( // Wrapped in Builder to access the Scaffold context
              builder: (context) => IconButton(
                icon: Icon(Icons.menu_rounded, color: theme.textTheme.titleMedium?.color),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () => Scaffold.of(context).openDrawer(), // Opens Drawer
              ),
            ),
          ),
          titleSpacing: 0,
          title: Text(activeList?.name ?? 'Listicle'), // Dynamically updates title
          backgroundColor: theme.cardColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          actions: [
            IconButton(icon: Icon(Icons.unfold_more_rounded, color: theme.textTheme.titleMedium?.color), onPressed: () {}),
            Consumer<ListProvider>(
              builder: (context, provider, child) {
                return PopupMenuButton<SortMode>(
                  icon: Icon(Icons.sort_rounded, color: theme.textTheme.titleMedium?.color),
                  onSelected: (SortMode mode) => provider.setSortMode(mode),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<SortMode>>[
                    const PopupMenuItem<SortMode>(value: SortMode.categories, child: Text('Group by Aisle')),
                    const PopupMenuItem<SortMode>(value: SortMode.types, child: Text('Group by Store')),
                    const PopupMenuItem<SortMode>(value: SortMode.az, child: Text('Alphabetical (A-Z)')),
                    const PopupMenuItem<SortMode>(value: SortMode.customFlat, child: Text('Custom Order (Flat)')),
                  ],
                );
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: theme.textTheme.titleMedium?.color),
              onSelected: (value) {
                if (value == 'select_multiple') {
                  context.read<ListProvider>().toggleMultiSelectMode();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'select_multiple',
                  child: Text('Select Multiple Items'),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            // 1. The Background: Empty State OR The Scrollable List
            displayList.isEmpty
                ? Center(
              child: Text(
                'All caught up!\nTap + to add your first item.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            )
                : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                // Dismiss swipe menus
                if (listProvider.openSwipeItemId.value != null) {
                  listProvider.openSwipeItemId.value = null;
                }

                // Smart Keyboard-Aware Scroll-to-Dismiss
                if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
                  if (!listProvider.isMultiSelectMode && listProvider.selectedItemIds.isNotEmpty) {
                    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                    if (isKeyboardOpen) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    } else {
                      listProvider.clearSelection();
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
                        top: 0.0,
                        bottom: listProvider.isEditMode ? 300 : safeBottomPadding + 100.0
                    ),
                    itemCount: displayList.length,
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) => context.read<ListProvider>().executeNativeReorder(oldIndex, newIndex),
                    proxyDecorator: (child, index, animation) {
                      return Material(color: Colors.transparent, elevation: 8.0, shadowColor: Colors.black45, child: child);
                    },
                    itemBuilder: (context, index) {
                      final item = displayList[index];

                      if (item is String) {
                        return Container(key: ValueKey('header_$item'), child: SectionHeader(title: item));
                      }

                      if (item is ListItem) {
                        final bool isSelected = listProvider.selectedItemIds.contains(item.id);

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
                          isEditMode: listProvider.isEditMode,
                          isSelected: isSelected,
                          onCheck: () {
                            final id = context.read<ListProvider>().toggleCompletion(item.id);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.title} checked off'),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(label: 'Undo', textColor: AppColors.primaryAction, onPressed: () => context.read<ListProvider>().restoreItems([id])),
                                )
                            );
                          },
                          onTap: () {
                            if (listProvider.openSwipeItemId.value != null) {
                              listProvider.openSwipeItemId.value = null;
                            } else {
                              if (listProvider.isMultiSelectMode) {
                                context.read<ListProvider>().toggleSelection(item.id);
                              } else {
                                context.read<ListProvider>().selectSingleItem(item.id);
                              }
                            }
                          },
                        );

                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('drag_${item.id}'),
                          index: index,
                          child: SwipeActionWrapper(
                            key: ValueKey('swipe_${item.id}'),
                            itemId: item.id,
                            requireConfirm: true,
                            onCheckout: () {
                              final id = context.read<ListProvider>().toggleCompletion(item.id);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.title} checked off'),
                                    behavior: SnackBarBehavior.floating,
                                    action: SnackBarAction(label: 'Undo', textColor: AppColors.primaryAction, onPressed: () => context.read<ListProvider>().restoreItems([id])),
                                  )
                              );
                            },
                            onEdit: () {
                              listProvider.clearSelection();
                              listProvider.toggleSelection(item.id);
                              listProvider.setFullEditRequest(true);
                              listProvider.openSwipeItemId.value = null;
                            },
                            onDelete: () {
                              final id = context.read<ListProvider>().deleteItem(item.id);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.title} deleted'),
                                    behavior: SnackBarBehavior.floating,
                                    action: SnackBarAction(label: 'Undo', textColor: AppColors.primaryAction, onPressed: () => context.read<ListProvider>().restoreItems([id])),
                                  )
                              );
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

            // 2. The Floating Action Button (Always in the tree now!)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              right: AppConstants.horizontalPadding,
              bottom: listProvider.isEditMode ? -100 : (safeBottomPadding + 16.0),
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => EditItemBottomSheet(
                      onSave: (title, attributes, type, category, quantity, unit) {
                        context.read<ListProvider>().addItem(
                          title,
                          attributes,
                          type,
                          category,
                          quantity,
                          unit,
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

            // 3. THE NEW FLUID CONTEXT SHEET (Always available now!)
            const FluidEditSheet(),
          ],
        ),
      ),
    );
  }
}