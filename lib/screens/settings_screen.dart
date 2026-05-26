import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings_models.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  // --- BOTTOM SHEET EDIT/ADD MODAL ---
  void _showEditSheet(BuildContext context, {StoreConfig? store, CategoryConfig? category, required bool isStoreMode}) {
    final provider = context.read<SettingsProvider>();
    final isEditing = store != null || category != null;

    final nameController = TextEditingController(text: store?.name ?? category?.name ?? '');
    final addressController = TextEditingController(text: store?.address ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Edit ${isStoreMode ? 'Store' : 'Category'}'
                      : 'New ${isStoreMode ? 'Store' : 'Category'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                if (isStoreMode) ...[
                  TextField(
                    controller: addressController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Address (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // FIXED: explicit Save and Cancel buttons (Bugs 6 & 7)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAction,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;

                          if (isStoreMode) {
                            if (isEditing) {
                              provider.updateStore(store!.id, nameController.text, addressController.text);
                            } else {
                              provider.addStore(nameController.text, addressController.text);
                            }
                          } else {
                            if (isEditing) {
                              provider.updateCategory(category!.id, nameController.text);
                            } else {
                              provider.addCategory(nameController.text);
                            }
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(isEditing ? 'Save Changes' : 'Create', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    if (!provider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.titleMedium?.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Manage Lists', style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
          bottom: TabBar(
            labelColor: AppColors.primaryAction,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            indicatorColor: AppColors.primaryAction,
            tabs: const [
              Tab(text: 'Stores'),
              Tab(text: 'Categories'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- STORES TAB ---
            Column(
              children: [
                // FIXED: Dedicated Toggle for Stores inside the list
                SwitchListTile(
                  title: const Text('Anchor "Any" to Top'),
                  subtitle: const Text('Keep untagged items at the top of your list'),
                  value: provider.anchorStoreToTop,
                  activeColor: AppColors.primaryAction,
                  onChanged: (val) => provider.toggleStoreAnchor(),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: provider.stores.length,
                    onReorder: provider.reorderStores,
                    itemBuilder: (context, index) {
                      final store = provider.stores[index];
                      return _buildStoreTile(context, store, index);
                    },
                  ),
                ),
              ],
            ),

            // --- CATEGORIES TAB ---
            Column(
              children: [
                // FIXED: Dedicated Toggle for Categories inside the list
                SwitchListTile(
                  title: const Text('Anchor "Everything Else" to Top'),
                  subtitle: const Text('Keep untagged items at the top of your list'),
                  value: provider.anchorCategoryToTop,
                  activeColor: AppColors.primaryAction,
                  onChanged: (val) => provider.toggleCategoryAnchor(),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: provider.categories.length,
                    onReorder: provider.reorderCategories,
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return _buildCategoryTile(context, category, index);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        floatingActionButton: Builder(
            builder: (ctx) {
              return FloatingActionButton(
                backgroundColor: AppColors.primaryAction,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  final tabController = DefaultTabController.of(ctx);
                  final isStore = tabController.index == 0;
                  _showEditSheet(context, isStoreMode: isStore);
                },
              );
            }
        ),
      ),
    );
  }

  // --- TILE BUILDERS ---

  Widget _buildStoreTile(BuildContext context, StoreConfig store, int index) {
    final theme = Theme.of(context);

    final tile = ListTile(
      key: ValueKey(store.id),
      tileColor: theme.cardColor,
      title: Text(store.name, style: TextStyle(fontWeight: store.isLocked ? FontWeight.bold : FontWeight.normal)),
      subtitle: store.address.isNotEmpty ? Text(store.address) : null,
      leading: store.isLocked ? const Icon(Icons.lock_outline, color: Colors.grey) : null,
      trailing: store.isLocked
          ? const SizedBox.shrink()
          : ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
      ),
      onTap: store.isLocked ? null : () => _showEditSheet(context, store: store, isStoreMode: true),
    );

    if (store.isLocked) return tile;

    return Dismissible(
      key: ValueKey('dismiss_${store.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.destructiveAction,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => context.read<SettingsProvider>().deleteStore(store.id),
      child: Column(
        children: [
          tile,
          const Divider(height: 1, indent: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, CategoryConfig category, int index) {
    final theme = Theme.of(context);

    final tile = ListTile(
      key: ValueKey(category.id),
      tileColor: theme.cardColor,
      title: Text(category.name, style: TextStyle(fontWeight: category.isLocked ? FontWeight.bold : FontWeight.normal)),
      leading: category.isLocked ? const Icon(Icons.lock_outline, color: Colors.grey) : null,
      trailing: category.isLocked
          ? const SizedBox.shrink()
          : ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
      ),
      onTap: category.isLocked ? null : () => _showEditSheet(context, category: category, isStoreMode: false),
    );

    if (category.isLocked) return tile;

    return Dismissible(
      key: ValueKey('dismiss_${category.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.destructiveAction,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => context.read<SettingsProvider>().deleteCategory(category.id),
      child: Column(
        children: [
          tile,
          const Divider(height: 1, indent: 16),
        ],
      ),
    );
  }
}