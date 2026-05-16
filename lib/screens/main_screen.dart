import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/add_item_modal.dart';
import '../components/section_header.dart';
import '../models/list_item.dart';
import '../services/list_provider.dart';
import '../components/list_item_card.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Controller to read the text input
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // Always dispose controllers to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final activeType = listProvider.activeType;
    final isGroupedByStore = listProvider.groupByStore;

    final items = List.of(listProvider.items);

    // 1. Sort the items based on the active grouping toggle
    items.sort((a, b) {
      String groupA = isGroupedByStore ? (a.locations.isNotEmpty ? a.locations.first : 'Anywhere') : a.category;
      String groupB = isGroupedByStore ? (b.locations.isNotEmpty ? b.locations.first : 'Anywhere') : b.category;

      int groupCompare = groupA.compareTo(groupB);
      if (groupCompare != 0) return groupCompare;
      return a.order.compareTo(b.order); // Secondary sort by user order
    });

    // 2. Flatten the data for the ReorderableList
    final List<dynamic> flatList = [];
    String currentGroup = '';

    for (var item in items) {
      String itemGroup = isGroupedByStore ? (item.locations.isNotEmpty ? item.locations.first : 'Anywhere') : item.category;

      if (itemGroup != currentGroup) {
        flatList.add(itemGroup); // Add the Header as a plain String
        currentGroup = itemGroup;
      }
      flatList.add(item); // Add the actual Item
    }

    // Helper to count items in a specific group
    int getGroupCount(String group) {
      return items.where((item) {
        String itemGroup = isGroupedByStore ? (item.locations.isNotEmpty ? item.locations.first : 'Anywhere') : item.category;
        return itemGroup == group;
      }).length;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,

      drawer: Drawer(
        // ... (Keep your existing Drawer code exactly as it is)
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
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              elevation: 0,
              centerTitle: true,
              backgroundColor: AppTheme.background,
              title: Text(
                activeType,
                style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              actions: [
                // The new Sort Toggle Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) {
                    if (value == 'toggle_group') {
                      context.read<ListProvider>().toggleGroupBy();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'toggle_group',
                      child: Row(
                        children: [
                          Icon(isGroupedByStore ? Icons.category : Icons.storefront, color: AppTheme.primary),
                          const SizedBox(width: 12),
                          Text(isGroupedByStore ? 'Group by Category' : 'Group by Store'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120, top: 8),
              sliver: SliverReorderableList(
                itemCount: flatList.length,
                itemBuilder: (context, index) {
                  final row = flatList[index];

                  // If it is a String, render the Header WITHOUT a drag listener
                  if (row is String) {
                    return Container(
                      key: ValueKey('header_$row'),
                      child: SectionHeader(title: row, itemCount: getGroupCount(row)),
                    );
                  }

                  // If it is an Item, render the Card WITH the drag listener
                  final item = row as ListItem;
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item.id),
                    index: index,
                    child: ListItemCard(item: item),
                  );
                },
                onReorder: (int oldIndex, int newIndex) {
                  // If they somehow try to drag a header, cancel it.
                  if (flatList[oldIndex] is String) return;

                  // Standard Flutter reorder adjustment
                  if (oldIndex < newIndex) newIndex -= 1;

                  // 1. Create a simulated copy of the list post-drop
                  final simulatedList = List.from(flatList);
                  final draggedItem = simulatedList.removeAt(oldIndex) as ListItem;
                  simulatedList.insert(newIndex, draggedItem);

                  // 2. Find the exact header directly above the drop location
                  String newGroup = 'Uncategorized';
                  for (int i = newIndex - 1; i >= 0; i--) {
                    if (simulatedList[i] is String) {
                      newGroup = simulatedList[i] as String;
                      break; // Found the header!
                    }
                  }

                  // 3. Extract just the items (ignoring headers) to save their new exact order
                  final reorderedItems = simulatedList.whereType<ListItem>().toList();

                  // 4. Send the new data to the Provider
                  context.read<ListProvider>().reorderAndMoveItem(
                      draggedItem.id,
                      newGroup,
                      reorderedItems
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        // ... (Keep your existing FAB code exactly as it is)
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddItemModal(activeListType: activeType),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  // Helper widget to keep the drawer code clean
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
        Navigator.pop(context); // Close drawer after selection
      },
    );
  }
}