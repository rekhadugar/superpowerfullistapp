import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SelectionSearchScreen extends StatefulWidget {
  final String title;
  final List<String> dictionary;
  final List<String> initialSelections;
  final bool isMultiSelect;

  const SelectionSearchScreen({
    Key? key,
    required this.title,
    required this.dictionary,
    required this.initialSelections,
    this.isMultiSelect = false,
  }) : super(key: key);

  @override
  State<SelectionSearchScreen> createState() => _SelectionSearchScreenState();
}

class _SelectionSearchScreenState extends State<SelectionSearchScreen> {
  late List<String> _localSelections;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _localSelections = List.from(widget.initialSelections);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String item) {
    setState(() {
      if (widget.isMultiSelect) {
        if (_localSelections.contains(item)) {
          _localSelections.remove(item);
        } else {
          _localSelections.add(item);
        }
      } else {
        _localSelections = [item];
        Navigator.pop(context, _localSelections); // Auto-pop on single select
      }
    });
  }

  void _createNew() {
    final newItem = _searchController.text.trim();
    if (newItem.isEmpty) return;

    setState(() {
      if (widget.isMultiSelect) {
        if (!_localSelections.contains(newItem)) {
          _localSelections.add(newItem);
        }
        _searchController.clear();
        _searchQuery = '';
      } else {
        Navigator.pop(context, [newItem]); // Auto-pop on single select
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Combine dictionary with any newly added custom selections so they remain visible
    final Set<String> fullDictionary = {...widget.dictionary, ..._localSelections};

    final filteredItems = fullDictionary
        .where((item) => item.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final bool showCreate = _searchQuery.isNotEmpty &&
        !fullDictionary.any((item) => item.toLowerCase() == _searchQuery.toLowerCase());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.cardColor,
        elevation: 0,
        actions: [
          if (widget.isMultiSelect)
            TextButton(
              onPressed: () => Navigator.pop(context, _localSelections),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search or create new...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length + (showCreate ? 1 : 0),
              itemBuilder: (context, index) {
                if (showCreate && index == 0) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAction.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppColors.primaryAction, size: 20),
                    ),
                    title: Text('Create "$_searchQuery"', style: const TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold)),
                    onTap: _createNew,
                  );
                }

                final itemIndex = showCreate ? index - 1 : index;
                final item = filteredItems[itemIndex];
                final isSelected = _localSelections.contains(item);

                return ListTile(
                  title: Text(item, style: theme.textTheme.titleMedium),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primaryAction)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () => _toggleSelection(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}