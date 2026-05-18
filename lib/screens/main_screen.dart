import 'dart:math' as math; // <-- Add this import at the top
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/item_form_modal.dart';
import '../components/main_options_sheet.dart';
import '../components/section_header.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../components/list_item_card.dart';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // THE FIX: A GPS tracker for the floating App Bar
  final GlobalKey _appBarKey = GlobalKey();

  final GlobalKey _phantomHeaderKey = GlobalKey();

  // THE FIX: The invisible bumper at the very end of the items
  final GlobalKey _endOfListKey = GlobalKey();

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Run the math once immediately after the first frame draws to set the initial header
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateStickyPhysics());
  }

  @override
  void dispose() {
    _controller.dispose();
    _headerState.dispose();
    super.dispose();
  }

  void _calculateStickyPhysics() {
    if (!mounted || _stackKey.currentContext == null) return;

    final RenderBox stackBox = _stackKey.currentContext!.findRenderObject() as RenderBox;
    final double stackTopY = stackBox.localToGlobal(Offset.zero).dy;

    double appBarBottomY = stackTopY;
    if (_appBarKey.currentContext != null) {
      final RenderBox appBarBox = _appBarKey.currentContext!.findRenderObject() as RenderBox;
      appBarBottomY = appBarBox.localToGlobal(Offset.zero).dy;
    }

    final double pinY = math.max(stackTopY, appBarBottomY);

    // --- THE FIX: Sliver-Immune Logical Tracking ---
    final listProvider = context.read<ListProvider>();
    final List<String> allHeaders = listProvider.groupedAndSortedItems.whereType<String>().toList();

    if (allHeaders.isEmpty) {
      if (_headerState.value.title.isNotEmpty) {
        _headerState.value = StickyHeaderState(title: '');
      }
      return;
    }

    String activeHeader = '';
    String? nextHeader;
    double nextHeaderY = double.infinity;
    int lastSeenAboveIndex = -1;

    for (int i = 0; i < allHeaders.length; i++) {
      final String headerTitle = allHeaders[i];
      final GlobalKey? key = _headerKeys[headerTitle];

      // Only check headers that are currently rendered on screen
      if (key != null && key.currentContext != null) {
        final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
        final dy = box.localToGlobal(Offset.zero).dy;

        if (dy <= pinY + 1.0) {
          lastSeenAboveIndex = i; // We saw this header above the pin line
        } else {
          // Found the very first visible header BELOW the pin line
          nextHeader = headerTitle;
          nextHeaderY = dy;
          // The active header MUST logically be the one right before this one!
          if (i > 0) activeHeader = allHeaders[i - 1];
          break;
        }
      }
    }

    // Fallback: If no headers are below the line, but we saw one above it, it's the active one.
    if (nextHeader == null && lastSeenAboveIndex != -1) {
      activeHeader = allHeaders[lastSeenAboveIndex];
    }

    // --- THE FIX: Dynamic Sub-Pixel Height Measurement ---
    // --- THE FIX: Dynamic Sub-Pixel Height & Bumper Push ---
    double pushOffset = 0.0;
    double stickyHeight = 56.0;
    if (_phantomHeaderKey.currentContext != null) {
      stickyHeight = (_phantomHeaderKey.currentContext!.findRenderObject() as RenderBox).size.height;
    }

    if (nextHeader != null && nextHeaderY < pinY + stickyHeight) {
      // Normal collision with the next category header
      pushOffset = nextHeaderY - (pinY + stickyHeight);
    } else if (nextHeader == null && _endOfListKey.currentContext != null) {
      // THE BUMPER: If there's no next header, the bottom of the list pushes it off!
      final RenderBox endBox = _endOfListKey.currentContext!.findRenderObject() as RenderBox;
      final double endDy = endBox.localToGlobal(Offset.zero).dy;
      if (endDy < pinY + stickyHeight) {
        pushOffset = endDy - (pinY + stickyHeight);
      }
    }

    final double dockY = pinY - stackTopY;

    if (_headerState.value.title != activeHeader ||
        _headerState.value.dockY != dockY ||
        _headerState.value.pushOffset != pushOffset) {
      _headerState.value = StickyHeaderState(
          title: activeHeader,
          dockY: dockY,
          pushOffset: pushOffset
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final activeType = listProvider.activeType;
    final List<dynamic> flatList = listProvider.groupedAndSortedItems;

    // NEW: Get the total screen height
    final double screenHeight = MediaQuery.of(context).size.height;

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
                padding: EdgeInsets.all(20.0),
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
            _calculateStickyPhysics();
            return false;
          },
          // THE FIX: Wrapped in a Stack to float the phantom header OUTSIDE the slivers!
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
                    // THE FIX: Turn off Material 3 scroll-tinting!
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    // ------------------------------------------
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
                    // Remove the massive bottom padding here, just keep it tight to the items
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 0, top: 8),
                    sliver: SliverReorderableList(
                      itemCount: flatList.length,
                      itemBuilder: (context, index) {
                        // ... (Keep your item builder code exactly the same) ...
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
                  // THE FIX: The Invisible Bumper & Sensible Runway
                  SliverToBoxAdapter(
                    child: SizedBox(
                      key: _endOfListKey, // Plant the tracker exactly where the items end
                      height: 160.0, // A native-feeling overscroll to clear the floating action button
                    ),
                  ),
                ],
              ),

              // The Floating Phantom Header
              ValueListenableBuilder<StickyHeaderState>(
                valueListenable: _headerState,
                builder: (context, state, child) {
                  if (state.title.isEmpty) return const SizedBox.shrink();

                  return Positioned(
                    // 1. Permanently parked at the bottom of the App Bar
                    top: state.dockY,
                    left: 0,
                    right: 0,
                    // 2. THE MASK: Chops off anything that tries to render above the docking line
                    child: ClipRect(
                      // 3. THE SLIDE: Animates the visual text upward inside the masked box
                      child: Transform.translate(
                        offset: Offset(0, state.pushOffset),
                        child: Container(
                          key: _phantomHeaderKey,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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


class StickyHeaderState {
  final String title;
  final double dockY;
  final double pushOffset;

  StickyHeaderState({
    required this.title,
    this.dockY = 0.0,
    this.pushOffset = 0.0
  });
}