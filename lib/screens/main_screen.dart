// Location: lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../widgets/edit_item_bottom_sheet.dart';
import '../widgets/list_item_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../widgets/section_header.dart';
import '../widgets/swipe_action_wrapper.dart';
import '../models/list_item.dart';
import '../engine/sticky_header_engine.dart'; // IMPORT THE ENGINE
import '../engine/sort_mode_engine.dart'; // IMPORT THE SORT ENGINE

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

    // CLEAN ARCHITECTURE: Ask the engine for the result, instead of doing math in the UI layer
    final newHeaderData = StickyHeaderEngine.calculatePhantomHeader(
      _scrollController.offset,
      provider.cumulativeYOffsets,
      provider.displayList,
    );

    // Only update the ValueNotifier if the data actually changed to prevent unnecessary rebuilds
    if (_phantomHeaderState.value.title != newHeaderData.title ||
        _phantomHeaderState.value.yOffset != newHeaderData.yOffset) {
      _phantomHeaderState.value = newHeaderData;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final width = MediaQuery.of(context).size.width;
        context.read<ListProvider>().updateViewportWidth(width);
      }
    });

    final listProvider = context.watch<ListProvider>();
    final displayList = listProvider.displayList;
    final theme = Theme.of(context);
    final double safeBottomPadding = MediaQuery.of(context).padding.bottom;
    const double menuHeight = 140.0;

    return GestureDetector(
      onTap: () {
        if (listProvider.openSwipeItemId.value != null) {
          listProvider.openSwipeItemId.value = null;
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leadingWidth: AppConstants.horizontalPadding + AppConstants.leadingBlockWidth + AppConstants.interElementGap,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppConstants.horizontalPadding),
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: theme.textTheme.titleMedium?.color),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () {},
            ),
          ),
          titleSpacing: 0,
          title: const Text('Listicle V2 Prototype'),
          backgroundColor: theme.cardColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.unfold_more_rounded, color: theme.textTheme.titleMedium?.color),
              onPressed: () {},
            ),
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
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: theme.textTheme.titleMedium?.color),
              onPressed: () {},
            ),
          ],
        ),
        body: displayList.isEmpty
            ? Center(child: Text('All caught up!', style: theme.textTheme.bodyMedium))
            : NotificationListener<ScrollStartNotification>(
          onNotification: (_) {
            if (listProvider.openSwipeItemId.value != null) {
              listProvider.openSwipeItemId.value = null;
            }
            return false;
          },
          child: Stack(
            children: [
              // ENTIRELY REPLACED: Native ReorderableListView handling C++ gap physics
              ReorderableListView.builder(
                scrollController: _scrollController,
                padding: EdgeInsets.only(
                    top: 0.0,
                    bottom: listProvider.isEditMode ? menuHeight + safeBottomPadding + 20 : safeBottomPadding + 100.0
                ),
                itemCount: displayList.length,
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) => context.read<ListProvider>().executeNativeReorder(oldIndex, newIndex),
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    elevation: 8.0,
                    shadowColor: Colors.black45,
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final item = displayList[index];

                  // Headers are visually static blocks bound to a key
                  if (item is String) {
                    return Container(
                      key: ValueKey('header_$item'),
                      child: SectionHeader(title: item),
                    );
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
                      isHighlighted: listProvider.flashItemId == item.id,
                      isDragging: false,
                      isEditMode: listProvider.isEditMode,
                      isSelected: isSelected,
                      onTap: () {
                        if (listProvider.openSwipeItemId.value != null) {
                          listProvider.openSwipeItemId.value = null;
                        } else {
                          context.read<ListProvider>().toggleSelection(item.id);
                        }
                      },
                    );

                    // Replaces LongPressDraggable to wire directly to Reorderable physics engine
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey('drag_${item.id}'),
                      index: index,
                      child: SwipeActionWrapper(
                        key: ValueKey('swipe_${item.id}'),
                        itemId: item.id,
                        requireConfirm: true,
                        onCheckout: () => context.read<ListProvider>().toggleCompletion(item.id),
                        onEdit: () {
                          // Collapse the swipe menu before opening the sheet
                          if (listProvider.openSwipeItemId.value != null) {
                            listProvider.openSwipeItemId.value = null;
                          }
                          // Launch the Full Edit Menu
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => EditItemBottomSheet(
                              item: item,
                              onSave: (newTitle, newAttributes, newType, newCategory) {
                                context.read<ListProvider>().editItem(item.id, newTitle, newAttributes, newType, newCategory);
                              },
                            ),
                          );
                        },
                        onDelete: () => context.read<ListProvider>().deleteItem(item.id),
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
                      child: Transform.translate(
                        offset: Offset(0, data.yOffset),
                        child: SectionHeader(title: data.title!),
                      ),
                    ),
                  );
                },
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: AppConstants.horizontalPadding,
                bottom: listProvider.isEditMode
                    ? (menuHeight + safeBottomPadding + 16.0)
                    : (safeBottomPadding + 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    if (listProvider.openSwipeItemId.value != null) listProvider.openSwipeItemId.value = null;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => EditItemBottomSheet(
                        item: ListItem(id: '', title: ''),
                        onSave: (newTitle, newAttributes, newType, newCategory) {
                          context.read<ListProvider>().addItem(newTitle, newAttributes, newType, newCategory);
                        },
                      ),
                    );
                  },
                  backgroundColor: AppColors.primaryAction,
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: 0, right: 0,
                bottom: listProvider.isEditMode ? 0 : -(menuHeight + safeBottomPadding + 20),
                child: Container(
                  height: menuHeight + safeBottomPadding,
                  padding: EdgeInsets.only(bottom: safeBottomPadding, top: 16.0, left: 24.0, right: 24.0),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: listProvider.selectedItemIds.length == 1
                                  ? Builder(
                                  builder: (context) {
                                    final singleId = listProvider.selectedItemIds.first;
                                    final draftQty = listProvider.getDraftQuantity(singleId);

                                    return Container(
                                      key: const ValueKey('stepper'),
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      decoration: BoxDecoration(
                                        color: theme.dividerColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(50.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                              icon: const Icon(Icons.remove, size: 20),
                                              onPressed: () => listProvider.updateDraftQuantity(singleId, -1),
                                              constraints: const BoxConstraints(), padding: const EdgeInsets.all(8.0)
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                            child: Text('$draftQty', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ),
                                          IconButton(
                                              icon: const Icon(Icons.add, size: 20),
                                              onPressed: () => listProvider.updateDraftQuantity(singleId, 1),
                                              constraints: const BoxConstraints(), padding: const EdgeInsets.all(8.0)
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                              )
                                  : Container(
                                key: const ValueKey('counter'),
                                height: 44,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAction.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(50.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.layers_rounded, color: AppColors.primaryAction, size: 20),
                                    const SizedBox(width: 8.0),
                                    Text('${listProvider.selectedItemIds.length} Selected', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primaryAction, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),

                            TextButton.icon(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                backgroundColor: theme.dividerColor.withOpacity(0.1),
                                foregroundColor: theme.textTheme.titleMedium?.color,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                minimumSize: const Size(0, 44),
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12.0),

                            TextButton.icon(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.15),
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                minimumSize: const Size(0, 44),
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: TextButton.icon(
                                onPressed: () => listProvider.clearSelection(),
                                style: TextButton.styleFrom(
                                  backgroundColor: theme.dividerColor.withOpacity(0.1),
                                  foregroundColor: theme.textTheme.titleMedium?.color,
                                  shape: const StadiumBorder(),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 20),
                                label: Text('Cancel', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => listProvider.commitEdits(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryAction,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 20),
                                label: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}