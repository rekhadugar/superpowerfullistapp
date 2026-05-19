import 'package:flutter/material.dart';
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

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _phantomHeaderKey = GlobalKey();
  final GlobalKey _endOfListKey = GlobalKey();
  final Map<String, GlobalKey> _headerKeys = {};

  final ValueNotifier<StickyHeaderState> _headerState = ValueNotifier<StickyHeaderState>(StickyHeaderState(title: ''));
  // FIXED: _overscrollY has been completely removed from memory.

  void _runPhysics() {
    StickyHeaderEngine.calculate(
      context: context,
      isMounted: mounted,
      stackKey: _stackKey,
      appBarKey: _appBarKey,
      phantomHeaderKey: _phantomHeaderKey,
      endOfListKey: _endOfListKey,
      headerKeys: _headerKeys,
      headerState: _headerState,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
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
    for (var row in flatList) {
      if (row is String) {
        _headerKeys.putIfAbsent(row, () => GlobalKey());
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
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    pinned: false,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: AppTheme.background,
                    centerTitle: true,
                    backgroundColor: AppTheme.background,

                    leading: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),

                    title: Text(
                      activeType,
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),

                    actions: [
                      IconButton(
                        icon: Icon(
                          listProvider.isGlobalCompactMode
                              ? Icons.view_headline
                              : Icons.view_compact_alt_outlined,
                          color: listProvider.isGlobalCompactMode ? AppTheme.primary : Colors.black,
                        ),
                        onPressed: () => listProvider.toggleGlobalCompactMode(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.black),
                        onPressed: _openOptionsSheet,
                      ),
                    ],

                    bottom: PreferredSize(
                      preferredSize: Size.zero,
                      child: Container(key: _appBarKey),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: AppConstants.padMedium,
                      right: AppConstants.padMedium,
                      bottom: AppConstants.padMedium,
                      top: 0,
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
          ],
        ),
      ),
    );
  }
}


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
