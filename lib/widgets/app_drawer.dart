import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_item.dart';
import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../providers/theme_provider.dart';
import '../models/list_type.dart';
import '../screens/create_list_screen.dart';
import '../providers/settings_provider.dart'; // NEW
import '../screens/settings_screen.dart';     // NEW

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MacroListProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final lists = provider.lists;
    final activeId = provider.activeListId;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'My Lists',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: ListType.values.map((type) {
                  final typeLists = lists.where((l) => l.type == type).toList();
                  if (typeLists.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Row(
                          children: [
                            Icon(type.icon, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              type.displayName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...typeLists.map((list) => ListTile(
                        title: Text(list.name),
                        selected: list.id == activeId,
                        selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                        onTap: () {
                          provider.setActiveList(list.id);
                          context.read<ListProvider>().loadItemsForList(list.id);
                          Navigator.pop(context);
                        },
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),

            // NEW: Settings Navigation Link
            // NEW: Settings Navigation Link
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              leading: const Icon(Icons.tune_rounded, color: Colors.grey),
              title: const Text('Manage Stores & Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () async {
                // FIXED: Capture the providers and navigator BEFORE we close the drawer
                final listProvider = context.read<ListProvider>();
                final settings = context.read<SettingsProvider>();
                final navigator = Navigator.of(context);

                // 1. SEED ENGINE: Harvest all existing strings from active and checked items!
                final Set<String> existingStores = {};
                final Set<String> existingCategories = {};

                for (var item in listProvider.activeItems) {
                  existingStores.add(item.type);
                  existingCategories.add(item.category);
                }
                for (var item in listProvider.checkedDisplayList) {
                  if (item is ListItem) {
                    existingStores.add(item.type);
                    existingCategories.add(item.category);
                  }
                }
                settings.seedFromExisting(existingStores.toList(), existingCategories.toList());

                // 2. Close drawer visually using the captured navigator
                navigator.pop();

                // 3. Navigate
                await navigator.push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen())
                );

                // 4. ON RETURN: Trigger Orphan Reassignment using captured providers!
                // No context.mounted check needed because we hold the direct references!
                listProvider.syncWithGlobalSettings(
                  settings.stores.map((s) => s.name).toList(),
                  settings.categories.map((c) => c.name).toList(),
                );
              },
            ),
            const Divider(height: 1),

            // Font Size Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Font Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: AppFontSize.values.map((size) {
                      final isSelected = themeProvider.fontSize == size;
                      return ChoiceChip(
                        label: Text(size.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) => themeProvider.setFontSize(size),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create New List'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateListScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}