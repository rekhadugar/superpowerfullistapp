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

    // Remove focus if tapping the background list
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
            IconButton(icon: Icon(Icons.more_vert_rounded, color: theme.textTheme.titleMedium?.color), onPressed: () {}),
          ],
        ),
        body: displayList.isEmpty
            ? Center(child: Text('All caught up!', style: theme.textTheme.bodyMedium))
            : NotificationListener<ScrollStartNotification>(
          onNotification: (_) {
            if (listProvider.openSwipeItemId.value != null) listProvider.openSwipeItemId.value = null;
            return false;
          },
          child: Stack(
            children: [
              ReorderableListView.builder(
                scrollController: _scrollController,
                padding: EdgeInsets.only(
                    top: 0.0,
                    bottom: listProvider.isEditMode ? 300 : safeBottomPadding + 100.0 // Extra padding when sheet is open
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
                      isHighlighted: listProvider.flashItemId == item.id,
                      isDragging: false,
                      isEditMode: listProvider.isEditMode,
                      isSelected: isSelected,
                      onTap: () {
                        if (listProvider.openSwipeItemId.value != null) {
                          listProvider.openSwipeItemId.value = null;
                        } else {
                          // Clicking a card toggles it and keeps the sheet in Glance/Batch mode
                          context.read<ListProvider>().toggleSelection(item.id);
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
                        onCheckout: () => context.read<ListProvider>().toggleCompletion(item.id),
                        onEdit: () {
                          // FIX: Clear existing selection, select this item, and force Full View
                          listProvider.clearSelection();
                          listProvider.toggleSelection(item.id);
                          listProvider.setFullEditRequest(true);
                          listProvider.openSwipeItemId.value = null;
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
                      child: Transform.translate(offset: Offset(0, data.yOffset), child: SectionHeader(title: data.title!)),
                    ),
                  );
                },
              ),

              // The Floating Action Button (Only visible if sheet is closed)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: AppConstants.horizontalPadding,
                bottom: listProvider.isEditMode ? -100 : (safeBottomPadding + 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    // Logic to open an empty sheet for adding will go here
                  },
                  backgroundColor: AppColors.primaryAction,
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),

              // THE NEW FLUID CONTEXT SHEET
              const FluidEditSheet(),
            ],
          ),
        ),
      ),
    );
  }
}