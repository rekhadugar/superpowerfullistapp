import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/item_form_modal.dart';
import '../components/main_options_sheet.dart';
import '../components/section_header.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../services/sticky_header_engine.dart'; // NEW IMPORT
import '../components/list_item_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart'; // NEW IMPORT

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ValueNotifier<StickyHeaderState> _headerState = ValueNotifier(
    StickyHeaderState(title: ''),
  );

  final Map<String, GlobalKey> _headerKeys = {};
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _phantomHeaderKey = GlobalKey();
  final GlobalKey _endOfListKey = GlobalKey();

  final TextEditingController _controller = TextEditingController();

  // THE FIX: Tracks the elastic displacement
  double _currentOverscroll = 0.0;

  // THE FIX: The Bulletproofing Listener. Reacts to data changes without scrolling!
  void _onDataChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runPhysicsEngine());
    }
  }

  void _runPhysicsEngine() {
    StickyHeaderEngine.calculate(
      context: context,
      isMounted: mounted,
      stackKey: _stackKey,
      appBarKey: _appBarKey,
      phantomHeaderKey: _phantomHeaderKey,
      endOfListKey: _endOfListKey,
      headerKeys: _headerKeys,
      headerState: _headerState,
      overscrollY: _currentOverscroll, // <-- Pass it here
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPhysicsEngine());

    // Bind the engine to the app state so it survives layout mutations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListProvider>().addListener(_onDataChanged);
    });
  }

  @override
  void dispose() {
    context.read<ListProvider>().removeListener(_onDataChanged);
    _controller.dispose();
    _headerState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final activeType = listProvider.activeType;
    final List<dynamic> flatList = listProvider.groupedAndSortedItems;

    int getGroupCount(String group) {
      int count = 0;
      bool inGroup = false;
      for (var row in flatList) {
        if (row is String) {
          if (row == group) {
            inGroup = true;
          } else if (inGroup) {
            break;
          }
        } else if (row is ListItem && inGroup) {
          count++;
        }
      }
      return count;
    }

    for (var row in flatList) {
      if (row is String) {
        _headerKeys.putIfAbsent(row, () => GlobalKey(debugLabel: row));
      }
    }
    _headerKeys.removeWhere((key, _) => !flatList.contains(key));

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: Drawer(
        backgroundColor: AppTheme.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppConstants.padLarge),
                child: Text('My Lists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ),
              const Divider(height: 1),
              _buildDrawerItem(context, 'All Items', Icons.all_inbox, activeType),
              const Divider(height: 1),
              _buildDrawerItem(context, 'Groceries', Icons.local_grocery_store, activeType),
              _buildDrawerItem(context, 'Hardware', Icons.handyman, activeType),
              _buildDrawerItem(context, 'Pharmacy', Icons.medical_services, activeType),
              _buildDrawerItem(context, 'Clothing', Icons.checkroom, activeType),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            // THE FIX: Mathematically capture the exact stretch of the bounce!
            if (notification.metrics.pixels < notification.metrics.minScrollExtent) {
              _currentOverscroll = -(notification.metrics.pixels - notification.metrics.minScrollExtent);
            } else if (notification.metrics.pixels > notification.metrics.maxScrollExtent) {
              _currentOverscroll = -(notification.metrics.pixels - notification.metrics.maxScrollExtent);
            } else {
              _currentOverscroll = 0.0;
            }

            _runPhysicsEngine();
            return false;
          },
          child: Stack(
            key: _stackKey,
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    pinned: false,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    centerTitle: true,
                    backgroundColor: AppTheme.background,
                    title: Text(
                      activeType,
                      style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(0),
                      child: SizedBox(key: _appBarKey),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const MainOptionsSheet(),
                          );
                        },
                      ),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: AppConstants.padMedium,
                      right: AppConstants.padMedium,
                      bottom: 0,
                      // THE FIX: Remove the 8px offset so the first header aligns perfectly!
                      top: 0,
                    ),
                    sliver: SliverReorderableList(
                      itemCount: flatList.length,
                      itemBuilder: (context, index) {
                        final row = flatList[index];

                        if (row is String) {
                          return Container(
                            key: _headerKeys[row],
                            child: SectionHeader(
                              title: row,
                              itemCount: getGroupCount(row),
                            ),
                          );
                        }

                        final item = row as ListItem;
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey(item.id),
                          index: index,
                          child: ListItemCard(item: item),
                        );
                      },
                      onReorder: (int oldIndex, int newIndex) {
                        if (flatList[oldIndex] is String) return;
                        if (oldIndex < newIndex) newIndex -= 1;

                        final simulatedList = List.from(flatList);
                        final draggedItem = simulatedList.removeAt(oldIndex) as ListItem;
                        simulatedList.insert(newIndex, draggedItem);

                        String newGroup = 'Uncategorized';
                        for (int i = newIndex - 1; i >= 0; i--) {
                          if (simulatedList[i] is String) {
                            newGroup = simulatedList[i] as String;
                            break;
                          }
                        }

                        final reorderedItems = simulatedList.whereType<ListItem>().toList();
                        context.read<ListProvider>().reorderAndMoveItem(draggedItem.id, newGroup, reorderedItems);
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
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padMedium),
                          color: AppTheme.background,
                          child: SectionHeader(
                            title: state.title,
                            itemCount: getGroupCount(state.title),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ItemFormModal(activeListType: activeType),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String activeType) {
    final isSelected = title == activeType;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : Colors.black87,
          )
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
      onTap: () {
        context.read<ListProvider>().setActiveType(title);
        Navigator.pop(context);
      },
    );
  }
}