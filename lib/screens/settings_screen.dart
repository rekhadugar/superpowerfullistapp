import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_list_type.dart';
import '../models/list_item.dart';
import '../models/macro_list.dart';
import '../models/settings_models.dart';
import '../providers/list_provider.dart';
import '../providers/macro_list_provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

// ==========================================
// LEVEL 1: THE HUB (List of all Types)
// ==========================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showCreateCustomTypeSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final axis1Ctrl = TextEditingController();
    final axis2Ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Custom Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Type Name (e.g., Wine Collection)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: axis1Ctrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Primary Group (e.g., Region)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: axis2Ctrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Secondary Group (e.g., Varietal)', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && axis1Ctrl.text.isNotEmpty && axis2Ctrl.text.isNotEmpty) {
                    context.read<SettingsProvider>().createCustomType(nameCtrl.text, axis1Ctrl.text, axis2Ctrl.text);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Create Type', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final macroProvider = context.watch<MacroListProvider>();
    final theme = Theme.of(context);

    // FIXED: Smart Visibility Engine
    // Hide system types if they are empty. Always show custom types so they can be deleted.
    final visibleTypes = settings.allTypes.where((type) {
      final hasActiveLists = macroProvider.lists.any((l) => l.typeId == type.id);
      return hasActiveLists || !type.isSystem;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.titleMedium?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Organize Lists', style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: visibleTypes.isEmpty
          ? const Center(child: Text('You have no active lists.'))
          : ListView.builder(
        itemCount: visibleTypes.length,
        itemBuilder: (context, index) {
          final type = visibleTypes[index];
          return ListTile(
            leading: Icon(IconData(type.iconCodePoint, fontFamily: 'MaterialIcons'), color: AppColors.primaryAction),
            title: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Manage ${type.axis1Label} & ${type.axis2Label}'),

            trailing: type.isSystem
                ? const Icon(Icons.chevron_right_rounded, color: Colors.grey)
                : IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.destructiveAction),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Custom Type?'),
                    content: Text('This will permanently delete the "${type.name}" taxonomy. ALL lists and items using this type will be wiped from your device. This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructiveAction),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await context.read<MacroListProvider>().deleteAllListsOfType(type.id);
                          context.read<SettingsProvider>().deleteCustomType(type.id);
                        },
                        child: const Text('Delete Everything', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TypeDetailScreen(listType: type)));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryAction,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Custom Type', style: TextStyle(color: Colors.white)),
        onPressed: () => _showCreateCustomTypeSheet(context),
      ),
    );
  }
}

// ==========================================
// LEVEL 2: TYPE DETAILS (3-Tab Architecture)
// ==========================================
class TypeDetailScreen extends StatefulWidget {
  final AppListType listType;
  const TypeDetailScreen({super.key, required this.listType});

  @override
  State<TypeDetailScreen> createState() => _TypeDetailScreenState();
}

class _TypeDetailScreenState extends State<TypeDetailScreen> with SingleTickerProviderStateMixin {
  bool _requiresSyncOnExit = false;

  late TabController _tabController;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _selectedIds.isNotEmpty) {
        setState(() => _selectedIds.clear());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final macroProvider = context.read<MacroListProvider>();
      final listProvider = context.read<ListProvider>();
      final settings = context.read<SettingsProvider>();

      if (macroProvider.activeList?.typeId == widget.listType.id) {
        _requiresSyncOnExit = true;

        final Set<String> existingA1 = {};
        final Set<String> existingA2 = {};

        for (var item in listProvider.activeItems) {
          existingA1.add(item.type);
          existingA2.add(item.category);
        }
        for (var item in listProvider.checkedDisplayList) {
          if (item is ListItem) {
            existingA1.add(item.type);
            existingA2.add(item.category);
          }
        }

        for (String s in existingA1) {
          if (s.toLowerCase() == 'any') continue;
          if (!settings.getAxis1Groups(widget.listType.id).any((g) => g.name.toLowerCase() == s.toLowerCase())) {
            settings.addGroup(widget.listType.id, s, '', isAxis1: true);
          }
        }
        for (String c in existingA2) {
          if (c.toLowerCase() == 'everything else') continue;
          if (!settings.getAxis2Groups(widget.listType.id).any((g) => g.name.toLowerCase() == c.toLowerCase())) {
            settings.addGroup(widget.listType.id, c, '', isAxis1: false);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerSyncOnExit(BuildContext context) {
    if (_requiresSyncOnExit && context.mounted) {
      final settings = context.read<SettingsProvider>();
      context.read<ListProvider>().syncWithGlobalSettings(
        settings.getAxis1Groups(widget.listType.id).map((g) => g.name).toList(),
        settings.getAxis2Groups(widget.listType.id).map((g) => g.name).toList(),
      );
    }
  }

  void _deleteSelectedItems() {
    final settings = context.read<SettingsProvider>();
    final macros = context.read<MacroListProvider>();

    for (String id in _selectedIds) {
      if (_tabController.index == 0) {
        macros.deleteList(id);
      } else if (_tabController.index == 1) {
        settings.deleteGroup(widget.listType.id, id, isAxis1: true);
      } else {
        settings.deleteGroup(widget.listType.id, id, isAxis1: false);
      }
    }
    setState(() => _selectedIds.clear());
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _showEditListSheet(BuildContext context, MacroList list) {
    final nameCtrl = TextEditingController(text: list.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'List Name', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        context.read<MacroListProvider>().updateList(list.id, nameCtrl.text);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.destructiveAction),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete List'),
                onPressed: () {
                  context.read<MacroListProvider>().deleteList(list.id);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEditGroupSheet(BuildContext context, {GroupConfig? group, required bool isAxis1}) {
    final provider = context.read<SettingsProvider>();
    final isEditing = group != null;
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final subtitleCtrl = TextEditingController(text: group?.subtitle ?? '');
    final label = isAxis1 ? widget.listType.axis1Label : widget.listType.axis2Label;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Edit $label' : 'New $label', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: subtitleCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Subtitle (Optional)', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAction, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        if (isEditing) {
                          provider.updateGroup(widget.listType.id, group.id, nameCtrl.text, subtitleCtrl.text, isAxis1: isAxis1);
                        } else {
                          provider.addGroup(widget.listType.id, nameCtrl.text, subtitleCtrl.text, isAxis1: isAxis1);
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(isEditing ? 'Save' : 'Create', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            if (isEditing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.destructiveAction),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  onPressed: () {
                    provider.deleteGroup(widget.listType.id, group.id, isAxis1: isAxis1);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final macroProvider = context.watch<MacroListProvider>();
    final theme = Theme.of(context);
    final activeLists = macroProvider.lists.where((l) => l.typeId == widget.listType.id).toList();

    final bool isBatchMode = _selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: isBatchMode
          ? AppBar(
        backgroundColor: AppColors.primaryAction,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() => _selectedIds.clear()),
        ),
        title: Text('${_selectedIds.length} Selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteSelectedItems,
          ),
        ],
      )
          : AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.titleMedium?.color),
          onPressed: () {
            _triggerSyncOnExit(context);
            Navigator.pop(context);
          },
        ),
        title: Text(widget.listType.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAction,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: AppColors.primaryAction,
          tabs: [
            const Tab(text: 'Lists'),
            Tab(text: widget.listType.axis1Label),
            Tab(text: widget.listType.axis2Label),
          ],
        ),
      ),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) _triggerSyncOnExit(context);
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: LIST REORDERING
            activeLists.isEmpty
                ? const Center(child: Text('No lists of this type yet.'))
                : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: activeLists.length,
              onReorder: (oldIndex, newIndex) {
                final globalOld = macroProvider.lists.indexOf(activeLists[oldIndex]);
                final globalNew = macroProvider.lists.indexOf(activeLists[newIndex < activeLists.length ? newIndex : activeLists.length - 1]);
                macroProvider.reorderLists(globalOld, globalNew);
              },
              itemBuilder: (context, index) {
                final list = activeLists[index];
                final isSelected = _selectedIds.contains(list.id);

                return ListTile(
                  key: ValueKey(list.id),
                  tileColor: theme.cardColor,
                  selected: isSelected,
                  selectedTileColor: AppColors.primaryAction.withValues(alpha: 0.1),
                  title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  leading: isBatchMode
                      ? Checkbox(value: isSelected, activeColor: AppColors.primaryAction, onChanged: (_) => _toggleSelection(list.id))
                      : const Icon(Icons.list, color: Colors.grey),
                  trailing: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                  onLongPress: () {
                    if (!isBatchMode) _toggleSelection(list.id);
                  },
                  onTap: () {
                    if (isBatchMode) {
                      _toggleSelection(list.id);
                    } else {
                      _showEditListSheet(context, list);
                    }
                  },
                );
              },
            ),

            // TAB 2: AXIS 1
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Anchor "Any" to Top'),
                  value: settings.getAnchorAxis1(widget.listType.id),
                  activeThumbColor: AppColors.primaryAction,
                  onChanged: (val) => settings.toggleAnchor(widget.listType.id, isAxis1: true),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: settings.getAxis1Groups(widget.listType.id).length,
                    onReorder: (oldIdx, newIdx) => settings.reorderGroups(widget.listType.id, oldIdx, newIdx, isAxis1: true),
                    itemBuilder: (context, index) => _buildGroupTile(context, settings.getAxis1Groups(widget.listType.id)[index], index, isAxis1: true),
                  ),
                ),
              ],
            ),

            // TAB 3: AXIS 2
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Anchor "Everything Else" to Top'),
                  value: settings.getAnchorAxis2(widget.listType.id),
                  activeThumbColor: AppColors.primaryAction,
                  onChanged: (val) => settings.toggleAnchor(widget.listType.id, isAxis1: false),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: settings.getAxis2Groups(widget.listType.id).length,
                    onReorder: (oldIdx, newIdx) => settings.reorderGroups(widget.listType.id, oldIdx, newIdx, isAxis1: false),
                    itemBuilder: (context, index) => _buildGroupTile(context, settings.getAxis2Groups(widget.listType.id)[index], index, isAxis1: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      floatingActionButton: isBatchMode ? const SizedBox.shrink() : FloatingActionButton(
        backgroundColor: AppColors.primaryAction,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (_tabController.index == 0) {
            _showEditListSheet(context, MacroList(id: DateTime.now().toString(), name: '', typeId: widget.listType.id, createdAt: DateTime.now(), editors: [AuthService.currentUserId!],));
          } else {
            _showEditGroupSheet(context, isAxis1: _tabController.index == 1);
          }
        },
      ),
    );
  }

  Widget _buildGroupTile(BuildContext context, GroupConfig group, int index, {required bool isAxis1}) {
    final theme = Theme.of(context);
    final isBatchMode = _selectedIds.isNotEmpty;
    final isSelected = _selectedIds.contains(group.id);

    final tile = ListTile(
      key: ValueKey(group.id),
      tileColor: theme.cardColor,
      selected: isSelected,
      selectedTileColor: AppColors.primaryAction.withValues(alpha: 0.1),
      title: Text(group.name, style: TextStyle(fontWeight: group.isLocked ? FontWeight.bold : FontWeight.normal)),
      subtitle: group.subtitle.isNotEmpty ? Text(group.subtitle) : null,
      leading: group.isLocked
          ? const Icon(Icons.lock_outline, color: Colors.grey)
          : isBatchMode
          ? Checkbox(value: isSelected, activeColor: AppColors.primaryAction, onChanged: (_) => _toggleSelection(group.id))
          : null,
      trailing: group.isLocked
          ? const SizedBox.shrink()
          : ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle_rounded, color: Colors.grey)),
      onLongPress: group.isLocked ? null : () {
        if (!isBatchMode) _toggleSelection(group.id);
      },
      onTap: group.isLocked ? null : () {
        if (isBatchMode) {
          _toggleSelection(group.id);
        } else {
          _showEditGroupSheet(context, group: group, isAxis1: isAxis1);
        }
      },
    );

    if (group.isLocked) return tile;

    return Dismissible(
      key: ValueKey('dismiss_${group.id}'),
      direction: DismissDirection.endToStart,
      background: Container(color: AppColors.destructiveAction, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline, color: Colors.white)),
      onDismissed: (_) => context.read<SettingsProvider>().deleteGroup(widget.listType.id, group.id, isAxis1: isAxis1),
      child: Column(children: [tile, const Divider(height: 1, indent: 16)]),
    );
  }
}