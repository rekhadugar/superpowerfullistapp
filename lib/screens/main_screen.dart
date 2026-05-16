import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/add_item_modal.dart';
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
    final items = listProvider.items;

    return Scaffold(
      backgroundColor: AppTheme.background,

      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              expandedHeight: 100.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Groceries', style: TextStyle(color: Colors.black)),
                titlePadding: EdgeInsets.only(left: 16, bottom: 16),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 120,
                top: 16,
              ),
              sliver: SliverReorderableList(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item.id),
                    index: index,
                    child: ListItemCard(item: item),
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
          // Trigger the Slide-up sheet!
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Allows the keyboard to push the sheet up
            backgroundColor: Colors.transparent, // Lets our custom container radius show
            builder: (context) => const AddItemModal(),
          );
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}