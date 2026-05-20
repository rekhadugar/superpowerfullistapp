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
              onPressed: () {
                // TODO: Implement Side Drawer Toggle
              },
            ),
          ),
          titleSpacing: 0,
          title: const Text('Listicle V2 Prototype'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.unfold_more_rounded, color: theme.textTheme.titleMedium?.color),
              tooltip: 'Expand / Collapse Menu',
              onPressed: () {
                // TODO: Implement Expand/Collapse Logic
              },
            ),
            Consumer<ListProvider>(
              builder: (context, provider, child) {
                return PopupMenuButton<SortMode>(
                  icon: Icon(Icons.sort_rounded, color: theme.textTheme.titleMedium?.color),
                  tooltip: 'Sort & Group Settings',
                  onSelected: (SortMode mode) {
                    provider.setSortMode(mode);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<SortMode>>[
                    const PopupMenuItem<SortMode>(
                      value: SortMode.categories,
                      child: Text('Group by Aisle'),
                    ),
                    const PopupMenuItem<SortMode>(
                      value: SortMode.types,
                      child: Text('Group by Store'),
                    ),
                    const PopupMenuItem<SortMode>(
                      value: SortMode.az,
                      child: Text('Alphabetical (A-Z)'),
                    ),
                    const PopupMenuItem<SortMode>(
                      value: SortMode.customFlat,
                      child: Text('Custom Order (Flat)'),
                    ),
                  ],
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: theme.textTheme.titleMedium?.color),
              tooltip: 'Options',
              onPressed: () {
                // TODO: Implement Options Menu
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (listProvider.openSwipeItemId.value != null) {
              listProvider.openSwipeItemId.value = null;
            }

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
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 0.0, bottom: 120.0),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final item = displayList[index];

                  if (item is String) {
                    return SectionHeader(
                      key: ValueKey('header_$item'),
                      title: item,
                    );
                  }

                  if (item is ListItem) {
                    return SwipeActionWrapper(
                      key: ValueKey('swipe_${item.id}'),
                      itemId: item.id,
                      requireConfirm: true,
                      onCheckout: () {
                        context.read<ListProvider>().toggleCompletion(item.id);
                      },
                      onEdit: () {
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
                      onDelete: () {
                        context.read<ListProvider>().deleteItem(item.id);
                      },
                      child: ListItemCard(
                        title: item.title,
                        nWrap: item.nWrap,
                        nTagRows: item.nTagRows,
                        attributeRows: item.attributeRows,
                        type: item.type,
                        category: item.category,
                        sortMode: listProvider.currentSortMode,
                        // THIS IS THE CRITICAL LINK WE MISSED:
                        isHighlighted: listProvider.flashItemId == item.id,
                        onTap: () {
                          if (listProvider.openSwipeItemId.value != null) {
                            listProvider.openSwipeItemId.value = null;
                          } else {
                            listProvider.toggleCompletion(item.id);
                          }
                        },
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
                    top: 0,
                    left: 0,
                    right: 0,
                    child: RepaintBoundary(
                      child: Transform.translate(
                        offset: Offset(0, data.yOffset),
                        child: SectionHeader(title: data.title!),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}