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
  double _overscrollY = 0.0;

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
      overscrollY: _overscrollY,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < notification.metrics.minScrollExtent) {
        _overscrollY = -(notification.metrics.pixels - notification.metrics.minScrollExtent);
      } else if (notification.metrics.pixels > notification.metrics.maxScrollExtent) {
        _overscrollY = -(notification.metrics.pixels - notification.metrics.maxScrollExtent);
      } else {
        _overscrollY = 0.0;
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

      drawer: const Drawer(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.padMedium),
            child: Text('App Drawer Placeholder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
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
                        return Container(
                          // FIXED: This forces the instantly shrunken card to suspend itself perfectly
                          // in the center of the original drag snapshot constraints, keeping it under your thumb!
                          alignment: Alignment.center,
                          child: Material(
                            color: Colors.transparent,
                            child: ListItemCard(
                              item: row as ListItem,
                              isCompact: listProvider.isGlobalCompactMode,
                              isDraggingProxy: true,
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

                        return ReorderableDelayedDragStartListener(
                          key: ValueKey((row as ListItem).id),
                          index: index,
                          child: ListItemCard(
                            item: row,
                            isCompact: listProvider.isGlobalCompactMode,
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
                          left: AppConstants.padMedium,
                          right: AppConstants.padMedium,
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

class _PseudoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ValueNotifier<String> activeHeader;
  final Map<String, GlobalKey> headerKeys;
  final List<dynamic> flatList;

  _PseudoHeaderDelegate(this.activeHeader, this.headerKeys, this.flatList);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Logic: Find the highest header whose GlobalKey is at or above the top (or very close)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String bestHeader = flatList.firstWhere((r) => r is String);

      for (var entry in headerKeys.entries) {
        final renderBox = entry.value.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final dy = renderBox.localToGlobal(Offset.zero).dy;
          // If the header is at or above the 60px sticky area, it's the active one
          if (dy <= 60) {
            bestHeader = entry.key;
          }
        }
      }
      if (activeHeader.value != bestHeader) activeHeader.value = bestHeader;
    });

    return ValueListenableBuilder<String>(
        valueListenable: activeHeader,
        builder: (context, header, child) {
          return Container(
            height: maxExtent, width: double.infinity,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 8.0),
            decoration: const BoxDecoration(color: AppTheme.background),
            child: Text(header, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 1.0)),
          );
        }
    );
  }

  @override
  double get maxExtent => 56.0;
  @override
  double get minExtent => 56.0;
  @override
  bool shouldRebuild(covariant _PseudoHeaderDelegate oldDelegate) => true;
}
