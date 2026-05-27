import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../engine/shopping_mode_engine.dart';
import '../models/list_item.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class ShoppingModeScreen extends StatefulWidget {
  const ShoppingModeScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen> {

  // FIXED: Removed initState completely.
  // The fetch is now safely controlled by RootNavigationScreen.

  void _showBanishDialog(BuildContext context, ListItem item, String store, ListProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hide "${item.title}"?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('This will prevent this item from showing up when you shop at $store.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructiveAction, padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.visibility_off, color: Colors.white),
                  label: const Text('Hide from this store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    provider.banishShoppingItem(item.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title} hidden from $store'), duration: const Duration(seconds: 2)));
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckableCard(ListItem item, String activeStore, ListProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: GestureDetector(
          onTap: () => provider.toggleShoppingItemCompletion(item.id),
          child: const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 28),
        ),
        title: Text(item.quantity > 0 ? '${item.title} - ${item.quantity} ${item.unit}' : item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: item.type.toLowerCase() != activeStore.toLowerCase() && item.type.toLowerCase() != 'any'
            ? Text('Tagged: ${item.type}', style: const TextStyle(color: AppColors.primaryAction, fontSize: 12))
            : null,
        onTap: () => provider.toggleShoppingItemCompletion(item.id),
        onLongPress: () => _showBanishDialog(context, item, activeStore, provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final theme = Theme.of(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // FIXED: Show a spinner while the database fetches the items across your lists
    if (listProvider.isLoadingShoppingMode) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Shopping Mode'), backgroundColor: theme.cardColor, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (listProvider.activeShoppingStore == null) {
      final availableShops = ShoppingModeEngine.getAvailableShops(listProvider.shoppingModeItems);

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Shopping Mode'), backgroundColor: theme.cardColor, elevation: 0),
        body: availableShops.isEmpty
            ? const Center(child: Text('No active shopping items found.'))
            : ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text('Where are you shopping?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...availableShops.map((shop) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.cardColor,
                  foregroundColor: theme.textTheme.bodyMedium?.color,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => listProvider.setShoppingStore(shop),
                child: Text(shop, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      );
    }

    final result = ShoppingModeEngine.process(
      allShoppingItems: listProvider.shoppingModeItems,
      activeStore: listProvider.activeShoppingStore!,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textTheme.titleMedium?.color),
          onPressed: () => listProvider.setShoppingStore(null),
        ),
        title: Text(listProvider.activeShoppingStore!, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: AppConstants.listBottomClearance + safeBottom),
        children: [
          if (result.mainItemsByCategory.isEmpty && result.alsoAvailableByCategory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('You have collected all items for this store! 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
            ),

          // 1. Render Main Categories
          ...result.mainItemsByCategory.entries.map((entry) {
            final category = entry.key;
            final mainItems = entry.value;
            final alsoAvailable = result.alsoAvailableByCategory[category] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(category.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryAction.withOpacity(0.8), letterSpacing: 1.2)),
                ),
                ...mainItems.map((item) => _buildCheckableCard(item, listProvider.activeShoppingStore!, listProvider)),

                // 2. Render "Also Available" nested in the same category
                if (alsoAvailable.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        collapsedBackgroundColor: theme.cardColor,
                        backgroundColor: theme.cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                        title: Text('Also available here (${alsoAvailable.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        children: alsoAvailable.map((item) => _buildCheckableCard(item, listProvider.activeShoppingStore!, listProvider)).toList(),
                      ),
                    ),
                  ),
              ],
            );
          }),

          // 3. Render Excluded Items (Bottom Footer)
          if (result.excludedItems.isNotEmpty) ...[
            const Divider(height: 64, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: Colors.grey,
                  collapsedIconColor: Colors.grey,
                  title: Text('Hidden from this store (${result.excludedItems.length})', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  children: result.excludedItems.map((item) => Opacity(
                    opacity: 0.5,
                    child: _buildCheckableCard(item, listProvider.activeShoppingStore!, listProvider),
                  )).toList(),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}