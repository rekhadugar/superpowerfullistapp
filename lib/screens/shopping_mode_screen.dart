import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/shopping_mode_engine.dart';
import '../engine/sort_mode_engine.dart';
import '../models/list_item.dart';
import '../providers/list_provider.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/fluid_edit_sheet.dart';
import '../widgets/list_item_card.dart';
import '../widgets/swipe_action_wrapper.dart';
import 'completed_items_screen.dart';

class ShoppingModeScreen extends StatefulWidget {
  const ShoppingModeScreen({super.key});

  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen> {

  // FIXED: Now accepts a nullable onUndo. If null, the Undo button is hidden.
  void _showActionToast(BuildContext context, String message, VoidCallback? onUndo) {
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

                if (onUndo != null) // Conditionally render the Undo button
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onUndo();
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
      menuColor: isHidden ? AppColors.primaryAction : Colors.orange,
      menuIcon: isHidden ? Icons.visibility : Icons.visibility_off,
      menuLabel: isHidden ? 'Tap To Unhide' : 'Tap To Hide',
      onCheckout: () {
        provider.toggleShoppingItemsCompletion([item.id]);
        _showActionToast(
            context,
            '${item.title} checked off',
                () => provider.restoreShoppingItems([item.id])
        );
      },
      onEdit: () {
        provider.clearAllInteractions();
        provider.setEditItem(item.id);
        provider.setFullEditRequest(true);
      },
      onDelete: () {
        if (isHidden) {
          provider.unbanishShoppingItems([item.id]);
          _showActionToast(
              context,
              '${item.title} restored to $activeStore',
                  () => provider.banishShoppingItems([item.id])
          );
        } else {
          provider.banishShoppingItems([item.id]);
          _showActionToast(
              context,
              '${item.title} hidden from $activeStore',
                  () => provider.unbanishShoppingItems([item.id])
          );
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
            provider.clearAllInteractions();
            provider.setEditItem(item.id);
            provider.setFullEditRequest(true);
          }
        },
        onCheck: () {
          provider.toggleShoppingItemsCompletion([item.id]);
          _showActionToast(
              context,
              '${item.title} checked off',
                  () => provider.restoreShoppingItems([item.id])
          );
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
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (result.mainItemsByCategory.isEmpty && result.alsoAvailableByCategory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text('You have collected all items for this store! 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
                        ),
                    ]),
                  ),
                ),

                // 1. Render Main Categories with Slivers (Sticky!)
                ...sortedMainCategories.map((category) {
                  final mainItems = result.mainItemsByCategory[category] ?? [];
                  final alsoAvailable = result.alsoAvailableByCategory[category] ?? [];

                  // FIXED: SliverMainAxisGroup binds the header to the list,
                  // causing the next header to natively push this one off screen.
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _CategoryHeaderDelegate(category, theme.scaffoldBackgroundColor),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          ...mainItems.map((item) => _buildItemCard(item, listProvider.activeShoppingStore!, listProvider)),
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
                        ]),
                      ),
                    ],
                  );
                }),

                SliverList(
                  delegate: SliverChildListDelegate([
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
                                  child: Align(alignment: Alignment.centerLeft, child: Text(category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0))),
                                ),
                                ...items.map((item) => _buildItemCard(item, listProvider.activeShoppingStore!, listProvider))
                              ];
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

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
                            children: result.excludedItems.map((item) => Opacity(opacity: 0.5, child: _buildItemCard(item, listProvider.activeShoppingStore!, listProvider, isHidden: true))).toList(),
                          ),
                        ),
                      ),
                    ],

                    if (listProvider.shoppingCompletedItems.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0, bottom: 24.0),
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedItemsScreen(isShoppingMode: true))),
                          icon: Icon(Icons.history_rounded, color: theme.textTheme.bodyMedium?.color),
                          label: Text('View Completed Items', style: theme.textTheme.bodyMedium),
                        ),
                      ),
                    ]
                  ]),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(height: isBatchMode ? 300 : AppConstants.listBottomClearance + safeBottom),
                ),
              ],
            ),
          ),

          const FluidEditSheet(),

          // --- ENHANCEMENT: 2-Row Stacked Batch Bar ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: 16.0,
            right: 16.0,
            bottom: isBatchMode ? safeBottom + AppConstants.snackbarBottomMargin : -150,
            height: 110.0, // FIXED: Expanded height to comfortably fit 2 rows
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  // ROW 1: Close, Count (Centered), Delete
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => listProvider.clearSelection(),
                        child: Icon(Icons.close, color: theme.colorScheme.onInverseSurface, size: 24),
                      ),
                      Expanded( // FIXED: Expands to perfectly center the text between the two 24px icons
                        child: Text(
                          '${listProvider.selectedItemIds.length} Selected',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onInverseSurface, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final ids = listProvider.selectedItemIds.toList();
                          listProvider.deleteShoppingItems(ids);
                          // FIXED: Now passes the Undo callback to restore deleted items
                          _showActionToast(context, '${ids.length} items deleted', () => listProvider.restoreDeletedShoppingItems(ids));
                        },
                        child: const Icon(Icons.delete_outline, color: AppColors.destructiveAction, size: 24),
                      ),
                    ],
                  ),

                  // ROW 2: Contextual Actions (Unhide, Hide, Check Off)
                  Builder(
                      builder: (context) {
                        final selectedItems = listProvider.shoppingModeItems.where((i) => listProvider.selectedItemIds.contains(i.id)).toList();
                        final storeLower = listProvider.activeShoppingStore!.toLowerCase();

                        final hasHidden = selectedItems.any((i) => i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower));
                        final hasActive = selectedItems.any((i) => !i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower));

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (hasHidden)
                              Expanded( // FIXED: Expanded forces the buttons to evenly balance the width
                                child: TextButton.icon(
                                  icon: const Icon(Icons.visibility, color: Colors.white, size: 16),
                                  label: const Text('UNHIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  onPressed: () {
                                    final hiddenIds = selectedItems.where((i) => i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower)).map((i) => i.id).toList();
                                    listProvider.unbanishShoppingItems(hiddenIds);
                                    _showActionToast(context, '${hiddenIds.length} items restored', () => listProvider.banishShoppingItems(hiddenIds));
                                  },
                                ),
                              ),
                            if (hasActive)
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.visibility_off, color: Colors.white, size: 16),
                                  label: const Text('HIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  onPressed: () {
                                    final activeIds = selectedItems.where((i) => !i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower)).map((i) => i.id).toList();
                                    listProvider.banishShoppingItems(activeIds);
                                    _showActionToast(context, '${activeIds.length} items hidden', () => listProvider.unbanishShoppingItems(activeIds));
                                  },
                                ),
                              ),
                            if (hasActive)
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.check, color: AppColors.primaryAction, size: 16),
                                  label: const Text('CHECK OFF', style: TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  onPressed: () {
                                    final activeIds = selectedItems.where((i) => !i.excludedLocations.map((e)=>e.toLowerCase()).contains(storeLower)).map((i) => i.id).toList();
                                    listProvider.toggleShoppingItemsCompletion(activeIds);
                                    _showActionToast(context, '${activeIds.length} items checked off', () => listProvider.restoreShoppingItems(activeIds));
                                  },
                                ),
                              ),
                          ],
                        );
                      }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final Color backgroundColor;

  _CategoryHeaderDelegate(this.title, this.backgroundColor);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      alignment: Alignment.bottomLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryAction.withValues(alpha: 0.8), letterSpacing: 1.2),
      ),
    );
  }

  @override
  double get maxExtent => 50.0;
  @override
  double get minExtent => 50.0;
  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) => oldDelegate.title != title;
}