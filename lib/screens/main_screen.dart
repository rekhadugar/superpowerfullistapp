import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/list_provider.dart';
import '../components/list_item_card.dart';

class MainScreen extends StatelessWidget { // <-- Changed from StatefulWidget to StatelessWidget!
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We "watch" the provider. If notifyListeners() is called, this build method runs again.
    final listProvider = context.watch<ListProvider>();
    final items = listProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listicle V2: Data Layer'),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: items.length,
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final item = items[index];

          return ReorderableDelayedDragStartListener(
            // The Key now securely uses our unique model ID
            key: ValueKey(item.id),
            index: index,
            // We pass the whole object so the card knows its name AND status
            child: ListItemCard(itemName: item.name),
          );
        },
        onReorder: (int oldIndex, int newIndex) {
          // We "read" the provider to call an action without constantly listening
          context.read<ListProvider>().reorderItems(oldIndex, newIndex);
        },
      ),
    );
  }
}