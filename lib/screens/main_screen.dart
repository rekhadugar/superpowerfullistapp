import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/item_form_modal.dart';
import '../components/main_options_sheet.dart';
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
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final activeType = listProvider.activeType;

    final List<dynamic> flatList = listProvider.groupedAndSortedItems;

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
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120, top: 8),
              sliver: SliverReorderableList(
                itemCount: flatList.length,
                itemBuilder: (context, index) {
                  final row = flatList[index];

                  if (row is String) {
                    return Container(
                      key: ValueKey('header_$row'),
                      child: SectionHeader(title: row), // CHANGED: Removed the item count
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