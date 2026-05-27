import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../engine/shopping_mode_engine.dart';
import '../models/list_item.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../widgets/fluid_edit_sheet.dart';
import '../widgets/list_item_card.dart';
import '../widgets/swipe_action_wrapper.dart';
import '../engine/sort_mode_engine.dart'; // Needed for ListItemCard sortMode

class ShoppingModeScreen extends StatefulWidget {
  const ShoppingModeScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen> {

  // Uses the exact same geometry logic as MainScreen to perfectly mask the Bottom Nav
  void _showActionToast(BuildContext context, String message, List<String> itemIds, ListProvider provider) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.fixed,
        backgroundColor: theme.colorScheme.inverseSurface,
        elevation: 0,
        content: SizedBox(
          height: 70.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold))),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    provider.restoreShoppingItems(itemIds);
                  },
                  child: const Text('Undo', style: TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildItemCard(ListItem item, String activeStore, ListProvider provider, {bool isHidden = false}) {
    final isBatchMode = provider.selectedItemIds.isNotEmpty;

    return SwipeActionWrapper(
      itemId: item.id,
      requireConfirm: true,
      isBatchModeActive: isBatchMode,

      // FIXED: Custom orange swipe for active items, blue swipe for hidden items
      menuColor: isHidden ? AppColors.primaryAction : Colors.orange,
      menuIcon: isHidden ? Icons.visibility : Icons.visibility_off,
      menuLabel: isHidden ? 'Tap To Unhide' : 'Tap To Hide',

      onCheckout: () {
        provider.toggleShoppingItemsCompletion([item.id]);
        _showActionToast(context, '${item.title} checked off', [item.id], provider);
      },
      onEdit: () {
        provider.clearAllInteractions();
        provider.setEditItem(item.id);
        provider.setFullEditRequest(true);
      },
      onDelete: () {
        if (isHidden) {
          provider.unbanishShoppingItems([item.id]);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title} restored to $activeStore')));
        } else {
          provider.banishShoppingItems([item.id]);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.title} hidden from $activeStore')));
        }
      },
      child: ListItemCard(
        title: item.title,
        quantity: item.quantity,
        unit: item.unit,
        nWrap: item.nWrap,
        nTagRows: item.nTagRows > 0 ? item.nTagRows : 1,
        attributeRows: item.attributeRows,
        type: item.type,
        category: item.category,
        sortMode: SortMode.categories,
        isHighlighted: false,
        isBatchModeActive: isBatchMode,
        isBatchSelected: provider.selectedItemIds.contains(item.id),
        isFluidEditing: provider.editItemId == item.id,
        onTap: () {
          if (isBatchMode) {
            provider.toggleSelection(item.id);
          } else {
            // FIXED: Tap always opens Fluid Edit in Shopping Mode
            provider.clearAllInteractions();
            provider.setEditItem(item.id);
            provider.setFullEditRequest(true);
          }
        },
        onCheck: () {
          provider.toggleShoppingItemsCompletion([item.id]);
          _showActionToast(context, '${item.title} checked off', [item.id], provider);
        },
        onToggleSelection: () => provider.toggleSelection(item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listProvider = context.watch<ListProvider>();
    final theme = Theme.of(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;

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

    // --- ENHANCEMENT 2: Custom Category Sorting ---
    final List<String> sortedMainCategories = result.mainItemsByCategory.keys.toList();
    sortedMainCategories.sort((a, b) {
      int idxA = listProvider.preferredCategoryOrder.indexOf(a);
      int idxB = listProvider.preferredCategoryOrder.indexOf(b);
      if (idxA == -1) idxA = 999;
      if (idxB == -1) idxB = 999;
      int cmp = idxA.compareTo(idxB);
      if (cmp == 0) return a.compareTo(b);
      return cmp;
    });

    // --- ENHANCEMENT 1: Orphaned Items Aggregation ---
    final List<String> orphanedCategories = result.alsoAvailableByCategory.keys
        .where((k) => !sortedMainCategories.contains(k)).toList();
    orphanedCategories.sort((a, b) {
      int idxA = listProvider.preferredCategoryOrder.indexOf(a);
      int idxB = listProvider.preferredCategoryOrder.indexOf(b);
      if (idxA == -1) idxA = 999;
      if (idxB == -1) idxB = 999;
      int cmp = idxA.compareTo(idxB);
      if (cmp == 0) return a.compareTo(b);
      return cmp;
    });

    final isBatchMode = listProvider.selectedItemIds.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.close, color: theme.textTheme.titleMedium?.color),
            onPressed: () {
              listProvider.clearSelection();
              listProvider.setShoppingStore(null);
            }
        ),
        title: Text(listProvider.activeShoppingStore!, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // LAYER 0: The Lists
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.only(bottom: isBatchMode ? 300 : AppConstants.listBottomClearance + safeBottom),
              children: [
                if (result.mainItemsByCategory.isEmpty && result.alsoAvailableByCategory.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('You have collected all items for this store! 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
                  ),

                // 1. Render Main Categories (Sorted by User Preference)
                ...sortedMainCategories.map((category) {
                  final mainItems = result.mainItemsByCategory[category] ?? [];
                  final alsoAvailable = result.alsoAvailableByCategory[category] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text(category.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryAction.withOpacity(0.8), letterSpacing: 1.2)),
                      ),
                      ...mainItems.map((item) => _buildItemCard(item, listProvider.activeShoppingStore!, listProvider)),

                      // 2. Render nested "Also Available" for this specific aisle
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
                              children: alsoAvailable.map((item) => _buildItemCard(item, listProvider.activeShoppingStore!, listProvider)).toList(),
                            ),
                          ),
                        ),
                    ],
                  );
                }),

                // --- ENHANCEMENT 1: Orphaned "All Other Shopping Items" ---
                if (orphanedCategories.isNotEmpty) ...[
                  const Divider(height: 64, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        iconColor: AppColors.primaryAction,
                        collapsedIconColor: theme.textTheme.bodyMedium?.color,
                        title: const Text('All Other Shopping Items', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('From different aisles or stores', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        children: orphanedCategories.expand((category) {
                          final items = result.alsoAvailableByCategory[category] ?? [];
                          return [
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0, bottom: 4.0, left: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                              ),
                            ),
                            ...items.map((item) => _buildItemCard(item, listProvider.activeShoppingStore!, listProvider))
                          ];
                        }).toList(),
                      ),
                    ),
                  ),
                ],

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
                          // FIXED: Pass isHidden: true so it uses the Unhide logic!
                          child: _buildItemCard(item, listProvider.activeShoppingStore!, listProvider, isHidden: true),
                        )).toList(),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),

          // FIXED: Injected the Edit Sheet so swipe-to-edit can actually render the UI
          const FluidEditSheet(),

          // --- ENHANCEMENT 3: Custom Shopping Mode Batch Bar ---
          // --- ENHANCEMENT 3: Custom Shopping Mode Batch Bar ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 16.0,
            right: 16.0,
            bottom: isBatchMode ? safeBottom + AppConstants.snackbarBottomMargin : -100,
            height: 70.0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.onInverseSurface),
                      onPressed: () => listProvider.clearSelection(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${listProvider.selectedItemIds.length}',
                      style: TextStyle(color: theme.colorScheme.onInverseSurface, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),

                    // FIXED: Dynamically check if selected items contain Hidden, Active, or Both
                    Builder(
                        builder: (context) {
                          final selectedItems = listProvider.shoppingModeItems.where((i) => listProvider.selectedItemIds.contains(i.id)).toList();
                          final storeLower = listProvider.activeShoppingStore!.toLowerCase();

                          final hasHidden = selectedItems.any((i) => i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower));
                          final hasActive = selectedItems.any((i) => !i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower));

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasHidden)
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility, color: Colors.white, size: 16),
                                  label: const Text('UNHIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    final hiddenIds = selectedItems.where((i) => i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower)).map((i) => i.id).toList();
                                    listProvider.unbanishShoppingItems(hiddenIds);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${hiddenIds.length} items restored')));
                                  },
                                ),
                              if (hasActive)
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility_off, color: Colors.white, size: 16),
                                  label: const Text('HIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    final activeIds = selectedItems.where((i) => !i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower)).map((i) => i.id).toList();
                                    listProvider.banishShoppingItems(activeIds);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${activeIds.length} items hidden')));
                                  },
                                ),
                              if (hasActive)
                                TextButton.icon(
                                  icon: const Icon(Icons.check, color: AppColors.primaryAction, size: 16),
                                  label: const Text('CHECK OFF', style: TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    final activeIds = selectedItems.where((i) => !i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower)).map((i) => i.id).toList();
                                    listProvider.toggleShoppingItemsCompletion(activeIds);
                                    _showActionToast(context, '${activeIds.length} items checked off', activeIds, listProvider);
                                  },
                                ),
                            ],
                          );
                        }
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}