import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/add_item_modal.dart';
import '../components/section_header.dart';
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

    final items = List.of(listProvider.items)
      ..sort((a, b) => a.category.compareTo(b.category));

    int getCategoryCount(String category) {
      return items.where((item) => item.category == category).length;
    }

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
            // The newly upgraded Floating App Bar
            SliverAppBar(
              floating: true,  // Hides when scrolling down the list
              snap: true,      // Snaps back instantly on any upward scroll
              pinned: false,   // Allows it to scroll out of view
              elevation: 0,
              centerTitle: true,
              backgroundColor: AppTheme.background,
              title: Text(
                activeType,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120, top: 8),
              sliver: SliverReorderableList(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final bool isFirstInCategory = index == 0 || items[index - 1].category != item.category;

                  Widget childWidget = ListItemCard(item: item);

                  if (isFirstInCategory) {
                    childWidget = Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: item.category, itemCount: getCategoryCount(item.category)),
                        childWidget,
                      ],
                    );
                  }

                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item.id),
                    index: index,
                    child: childWidget,
                  );
                },
                onReorder: (int oldIndex, int newIndex) {
                  context.read<ListProvider>().reorderItems(oldIndex, newIndex);
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