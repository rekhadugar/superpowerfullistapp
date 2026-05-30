import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/list_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class AxisSelectorScreen extends StatefulWidget {
  final bool isAxis1;
  final String typeId;

  const AxisSelectorScreen({super.key, required this.isAxis1, required this.typeId});

  @override
  State<AxisSelectorScreen> createState() => _AxisSelectorScreenState();
}

class _AxisSelectorScreenState extends State<AxisSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleTap(String value, int index) async {
    setState(() => _highlightedIndex = index);
    FocusScope.of(context).unfocus();
    // 50ms flash before popping
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listProvider = context.watch<ListProvider>();
    final settings = context.watch<SettingsProvider>();

    final appType = settings.getTypeById(widget.typeId);
    final axisName = widget.isAxis1 ? appType.axis1Label : appType.axis2Label;

    // 1. Fetch base settings (exclude empty states)
    final baseGroups = widget.isAxis1
        ? settings.getAxis1Groups(widget.typeId).map((g) => g.name).where((n) => n != 'Any' && n != 'Everything Else').toList()
        : settings.getAxis2Groups(widget.typeId).map((g) => g.name).where((n) => n != 'Any' && n != 'Everything Else').toList();

    // 2. Fetch popular from global dictionary
    final dict = listProvider.searchSmartDictionary('');
    final List<String> allItems = List.from(baseGroups);

    for (var item in dict) {
      String val = widget.isAxis1 ? item.store : item.category;
      if (val.isNotEmpty && val != 'Any' && val != 'Everything Else' && !allItems.contains(val)) {
        allItems.add(val);
      }
    }

    // 3. Filter based on query
    final filteredItems = _query.isEmpty
        ? allItems
        : allItems.where((item) => item.toLowerCase().contains(_query.toLowerCase())).toList();

    // 4. Determine if the exact query exists
    final bool isExactMatch = allItems.any((item) => item.toLowerCase() == _query.toLowerCase());

    // Determine the total count of items in the list (including the dynamic top item if searching)
    final int itemCount = _query.isNotEmpty ? filteredItems.length + 1 : filteredItems.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Search or add $axisName...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor.withValues(alpha: 0.5)),
          ),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {

          // Logic for the dynamic top item when searching
          if (_query.isNotEmpty && index == 0) {
            final String displayValue = isExactMatch
                ? allItems.firstWhere((item) => item.toLowerCase() == _query.toLowerCase())
                : _query;

            return _buildListItem(
              index: index,
              title: displayValue,
              isNew: !isExactMatch,
              theme: theme,
              onTap: () => _handleTap(displayValue, index),
            );
          }

          // Offset the index for the filtered list if the dynamic top item is present
          final itemIndex = _query.isNotEmpty ? index - 1 : index;
          final String item = filteredItems[itemIndex];

          // Prevent duplicating the exact match if it was already shown at index 0
          if (_query.isNotEmpty && item.toLowerCase() == _query.toLowerCase()) {
            return const SizedBox.shrink();
          }

          return _buildListItem(
            index: index,
            title: item,
            isNew: false,
            theme: theme,
            onTap: () => _handleTap(item, index),
          );
        },
      ),
    );
  }

  Widget _buildListItem({
    required int index,
    required String title,
    required bool isNew,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final bool isHighlighted = _highlightedIndex == index;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: isHighlighted ? AppColors.primaryAction.withValues(alpha: 0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              isNew ? Icons.add_circle_rounded : Icons.label_rounded,
              color: isNew ? AppColors.primaryAction : theme.hintColor,
              size: 24,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isNew ? FontWeight.bold : FontWeight.w500,
                  color: isNew ? AppColors.primaryAction : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isNew ? AppColors.primaryAction.withValues(alpha: 0.1) : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isNew ? 'New' : 'Existing',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isNew ? AppColors.primaryAction : theme.hintColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}