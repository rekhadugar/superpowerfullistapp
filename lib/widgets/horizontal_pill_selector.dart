import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/selection_search_screen.dart';

class HorizontalPillSelector extends StatelessWidget {
  final String title;
  final List<String> dictionary;
  final List<String> selectedItems;
  final bool isMultiSelect;
  final Function(List<String>) onSelectionChanged;

  const HorizontalPillSelector({
    Key? key,
    required this.title,
    required this.dictionary,
    required this.selectedItems,
    this.isMultiSelect = false,
    required this.onSelectionChanged,
  }) : super(key: key);

  void _openSearchScreen(BuildContext context) async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionSearchScreen(
          title: 'Select $title',
          dictionary: dictionary,
          initialSelections: selectedItems,
          isMultiSelect: isMultiSelect,
        ),
      ),
    );

    if (result != null) {
      onSelectionChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String emptyFallback = title == 'Category' ? 'Everything Else' : (title == 'Store' ? 'Any' : 'None');

    List<String> pillsToDisplay = [];
    if (isMultiSelect) {
      // Tags: Show all selected first, then the rest
      pillsToDisplay.addAll(selectedItems);
      pillsToDisplay.addAll(dictionary.where((d) => !selectedItems.contains(d)));
    } else {
      // Store/Category: Show active selection (or fallback) first, then the rest
      final activeItem = selectedItems.isNotEmpty && selectedItems.first.isNotEmpty ? selectedItems.first : emptyFallback;
      pillsToDisplay.add(activeItem);
      pillsToDisplay.addAll(dictionary.where((d) => d != activeItem && d != emptyFallback));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Add Button
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              GestureDetector(
                onTap: () => _openSearchScreen(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAction.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.add, size: 16, color: AppColors.primaryAction),
                      SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: AppColors.primaryAction, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: pillsToDisplay.map((item) {
              final bool isSelected = isMultiSelect
                  ? selectedItems.contains(item)
                  : (selectedItems.isNotEmpty && selectedItems.first == item) ||
                  (selectedItems.isEmpty && (item == emptyFallback));

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    if (isMultiSelect) {
                      List<String> newSelections = List.from(selectedItems);
                      if (newSelections.contains(item)) {
                        newSelections.remove(item);
                      } else {
                        newSelections.add(item);
                      }
                      onSelectionChanged(newSelections);
                    } else {
                      onSelectionChanged([item]);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryAction : theme.cardColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryAction : theme.dividerColor,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme.titleMedium?.color,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}