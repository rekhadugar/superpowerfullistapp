import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../components/item_form_modal.dart';
import '../components/main_options_sheet.dart';
import '../components/section_header.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../components/list_item_card.dart';
import '../services/sticky_header_engine.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _phantomHeaderKey = GlobalKey();
  final GlobalKey _endOfListKey = GlobalKey();

  final Map<String, GlobalKey> _headerKeys = {};
  final Map<String, GlobalKey> _itemKeys = {};

  final ValueNotifier<StickyHeaderState> _headerState = ValueNotifier<StickyHeaderState>(StickyHeaderState(title: ''));
  final ScrollController _scrollController = ScrollController();

  late AnimationController _appBarController;

  bool _isSnapping = false;
  int _activeSnapId = 0;
  ScrollDirection _lastUserScrollDirection = ScrollDirection.idle;

  @override
  void initState() {
    super.initState();
    _appBarController = AnimationController(
      vsync: this,
      lowerBound: -76.0,
      upperBound: 0.0,
      value: 0.0,
      duration: const Duration(milliseconds: 150), // Tightened for serial animation
    );

    _appBarController.addListener(() {
      _runPhysics();
    });
  }

  @override
  void dispose() {
    _appBarController.dispose();
    _scrollController.dispose();
    _headerState.dispose();
    super.dispose();
  }

  void _runPhysics() {
    final listProvider = context.read<ListProvider>();
    StickyHeaderEngine.calculate(
      context: context,
      isMounted: mounted,
      stackKey: _stackKey,
      appBarKey: _appBarKey,
      phantomHeaderKey: _phantomHeaderKey,
      endOfListKey: _endOfListKey,
      headerKeys: _headerKeys,
      itemKeys: _itemKeys,
      flatList: listProvider.groupedAndSortedItems,
      headerState: _headerState,
      scrollController: _scrollController,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activeSnapId++;
    _isSnapping = false;

    if (_appBarController.isAnimating) {
      _appBarController.stop();
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (_scrollController.position.userScrollDirection != ScrollDirection.idle) {
        _lastUserScrollDirection = _scrollController.position.userScrollDirection;
      }

      // FIX: Ensure slow scrolls are perfectly captured without delta loss
      if (notification.scrollDelta != null && !_isSnapping) {
        double newY = (_appBarController.value - notification.scrollDelta!).clamp(-76.0, 0.0);
        _appBarController.value = newY;
      }

      // Absolute top boundary lock
      if (_scrollController.hasClients && _scrollController.offset <= 0.0 && !_isSnapping) {
        _appBarController.value = 0.0;
      }

      _runPhysics();
    }

    if (notification is ScrollStartNotification) {
      final provider = context.read<ListProvider>();
      if (provider.expandedItemId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.clearExpandedItem();
        });
      }
    }

    if (notification is ScrollEndNotification && !_isSnapping) {
      _isSnapping = true;
      _activeSnapId++;
      final int currentSnapId = _activeSnapId;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final double currentY = _appBarController.value;
        final bool isAppBarPartial = currentY > -75.9 && currentY < -0.1; // Wider float tolerance

        // --- PHASE 1: RESOLVE THE APP BAR ANCHOR ---
        if (isAppBarPartial) {
          double targetAppBarY;
          if (_lastUserScrollDirection == ScrollDirection.reverse) {
            targetAppBarY = 0.0;
          } else if (_lastUserScrollDirection == ScrollDirection.forward) {
            targetAppBarY = -76.0;
          } else {
            targetAppBarY = currentY < -38.0 ? -76.0 : 0.0;
          }

          await _appBarController.animateTo(
            targetAppBarY,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }

        // Abort if the user touched the screen during Phase 1
        if (!mounted || _activeSnapId != currentSnapId) return;

        // --- PHASE 2: STATIC RECALCULATION & CELL SNAP ---
        // Force the engine to look at the new, completely stationary layout
        _runPhysics();

        final snapDelta = _headerState.value.snapDelta;

        if (snapDelta.abs() > 1.0 && snapDelta.abs() < 150.0 && _scrollController.hasClients) {
          final targetOffset = _scrollController.offset + snapDelta;

          if (targetOffset >= 0 && targetOffset <= _scrollController.position.maxScrollExtent) {
            await _scrollController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
            );
          }
        }

        if (mounted && _activeSnapId == currentSnapId) {
          _isSnapping = false;
        }
      });
    }
    return false;
  }

  void _openOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MainOptionsSheet(),
    );
  }

  void _openAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemFormModal(
        activeListType: context.read<ListProvider>().activeType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final activeType = listProvider.activeType;
    final flatList = listProvider.groupedAndSortedItems;

    _headerKeys.clear();
    _itemKeys.clear();
    for (var row in flatList) {
      if (row is String) {
        _headerKeys.putIfAbsent(row, () => GlobalKey());
      } else if (row is ListItem) {
        _itemKeys.putIfAbsent(row.id, () => GlobalKey());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runPhysics();
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: AppDrawer(
        availableLists: listProvider.availableLists,
        activeType: listProvider.activeType,
        onListSelected: (String newListType) {
          listProvider.setActiveType(newListType);
          _scaffoldKey.currentState?.closeDrawer();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemModal,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          key: _stackKey,
          children: [
            Listener(
              onPointerDown: _handlePointerDown,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 76.0),
                    ),

                    SliverPadding(
                      padding: EdgeInsets.only(
                        left: AppConstants.padMedium,
                        right: AppConstants.padMedium,
                        bottom: AppConstants.padMedium,
                        top: listProvider.isGlobalCompactMode ? 20.0 : 0.0,
                      ),
                      sliver: SliverReorderableList(
                        itemCount: flatList.length,
                        proxyDecorator: (Widget child, int index, Animation<double> animation) {
                          final row = flatList[index];
                          if (row is String) return child;
                          final item = row as ListItem;

                          return Container(
                            alignment: Alignment.center,
                            child: Material(
                              color: Colors.transparent,
                              child: ListItemCard(
                                item: item,
                                isCompact: listProvider.isGlobalCompactMode,
                                isDraggingProxy: true,
                                isExpanded: listProvider.expandedItemId == item.id,
                                onToggleStatus: () {},
                                onDelete: () {},
                                onRestore: () {},
                                onToggleExpand: () {},
                                onUpdateQuantity: (_) {},
                                onEdit: () {},
                              ),
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          final row = flatList[index];

                          if (row is String) {
                            return Container(
                              key: _headerKeys[row],
                              child: SectionHeader(
                                  title: row,
                                  isCompact: listProvider.isGlobalCompactMode
                              ),
                            );
                          }

                          final item = row as ListItem;

                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(item.id),
                            index: index,
                            child: Container(
                              key: _itemKeys[item.id],
                              child: ListItemCard(
                                item: item,
                                isCompact: listProvider.isGlobalCompactMode,
                                isExpanded: listProvider.expandedItemId == item.id,
                                onToggleStatus: () => context.read<ListProvider>().toggleItemStatus(item.id, item.isCompleted),
                                onDelete: () => context.read<ListProvider>().deleteItem(item.id),
                                onRestore: () => context.read<ListProvider>().restoreItem(item.id),
                                onToggleExpand: () => context.read<ListProvider>().toggleExpandedItem(item.id),
                                onUpdateQuantity: (q) => context.read<ListProvider>().updateQuantity(item.id, q),
                                onEdit: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => ItemFormModal(
                                      activeListType: listProvider.activeType,
                                      existingItem: item,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        onReorder: (int oldIndex, int newIndex) {
                          listProvider.reorderItems(oldIndex, newIndex);
                        },
                        onReorderStart: (int index) {
                          listProvider.clearExpandedItem();
                        },
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        key: _endOfListKey,
                        height: AppConstants.endOfListRunway,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ValueListenableBuilder<StickyHeaderState>(
              valueListenable: _headerState,
              builder: (context, state, child) {
                if (state.title.isEmpty) return const SizedBox.shrink();

                return Positioned(
                  top: state.dockY,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: Transform.translate(
                      offset: Offset(0, state.pushOffset),
                      child: Container(
                        key: _phantomHeaderKey,
                        height: listProvider.isGlobalCompactMode ? 36.0 : 56.0,
                        width: double.infinity,
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.only(
                          left: AppConstants.padMedium * 2,
                          right: AppConstants.padMedium * 2,
                          bottom: AppConstants.padSmall,
                        ),
                        decoration: const BoxDecoration(color: AppTheme.background),
                        child: Text(
                          state.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            AnimatedBuilder(
              animation: _appBarController,
              builder: (context, child) {
                return Positioned(
                  top: _appBarController.value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 76.0,
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padMedium),
                            child: Row(
                              children: [
                                listProvider.isSearching
                                    ? IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                                  onPressed: () => listProvider.toggleSearch(),
                                )
                                    : IconButton(
                                  icon: const Icon(Icons.menu),
                                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                ),
                                Expanded(
                                  child: Center(
                                    child: listProvider.isSearching
                                        ? TextField(
                                      autofocus: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Search items, tags, stores...',
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(color: Colors.black45, fontSize: 16),
                                      ),
                                      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
                                      onChanged: (value) => listProvider.setSearchQuery(value),
                                    )
                                        : Text(
                                      activeType,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primary,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!listProvider.isSearching) ...[
                                  IconButton(
                                    icon: Icon(
                                      listProvider.isGlobalCompactMode ? Icons.unfold_less : Icons.unfold_more,
                                      color: listProvider.isGlobalCompactMode ? Colors.black : AppTheme.primary,
                                    ),
                                    onPressed: () => listProvider.toggleGlobalCompactMode(),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert, color: Colors.black),
                                    onPressed: _openOptionsSheet,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Container(key: _appBarKey, height: 0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// AppDrawer class remains unchanged


class AppDrawer extends StatelessWidget {
  final List<String> availableLists;
  final String activeType;
  final ValueChanged<String> onListSelected;

  const AppDrawer({
    required this.availableLists,
    required this.activeType,
    required this.onListSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.padMedium, vertical: 24.0),
              child: Text(
                'My Lists',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: availableLists.length,
                itemBuilder: (context, index) {
                  final listName = availableLists[index];
                  final isSelected = listName == activeType;

                  return ListTile(
                    leading: Icon(
                      listName == 'All Items' ? Icons.all_inbox : Icons.list_alt,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    title: Text(
                      listName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
                    onTap: () => onListSelected(listName),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
