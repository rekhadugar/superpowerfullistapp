import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/selection_search_screen.dart';

class HorizontalPillSelector extends StatelessWidget {
  final String title;
  final List<String> dictionary;
  final List<String> selectedItems;
  final bool isMultiSelect;
  final bool isTag; // NEW: Controls the compact, boundary-highlighted styling
  final Function(List<String>) onSelectionChanged;

  const HorizontalPillSelector({
    Key? key,
    required this.title,
    required this.dictionary,
    required this.selectedItems,
    this.isMultiSelect = false,
    this.isTag = false, // Defaults to false for Store and Category
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
      pillsToDisplay.addAll(selectedItems);
      pillsToDisplay.addAll(dictionary.where((d) => !selectedItems.contains(d)));
    } else {
      final activeItem = selectedItems.isNotEmpty && selectedItems.first.isNotEmpty ? selectedItems.first : emptyFallback;
      pillsToDisplay.add(activeItem);
      pillsToDisplay.addAll(dictionary.where((d) => d != activeItem && d != emptyFallback));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: pillsToDisplay.map((item) {
              final bool isFallback = item == emptyFallback;
              final bool isSelected = isMultiSelect
                  ? selectedItems.contains(item)
                  : (selectedItems.isNotEmpty && selectedItems.first == item) ||
                  (selectedItems.isEmpty && isFallback);

              // We only show the 'x' if it's selected AND it's not the default fallback state
              final bool showX = isSelected && !isFallback;

              // Style Definitions based on isTag and isSelected
              Color bgColor;
              Color textColor;
              Border border;

              if (isSelected) {
                if (isTag) {
                  // NEW: Boundary highlighted only for tags
                  bgColor = theme.scaffoldBackgroundColor; // Match the background
                  textColor = AppColors.primaryAction;
                  border = Border.all(color: AppColors.primaryAction, width: 1.5);
                } else {
                  bgColor = AppColors.primaryAction;
                  textColor = Colors.white;
                  border = Border.all(color: AppColors.primaryAction, width: 1.0);
                }
              } else {
                bgColor = theme.cardColor;
                textColor = theme.textTheme.titleMedium?.color ?? Colors.black;
                border = Border.all(color: theme.dividerColor, width: 1.0);
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    if (isMultiSelect) {
                      List<String> newSelections = List.from(selectedItems);
                      if (isSelected) {
                        newSelections.remove(item);
                      } else {
                        newSelections.add(item);
                      }
                      onSelectionChanged(newSelections);
                    } else {
                      // NEW: Unselect to empty if it's already selected
                      if (isSelected && !isFallback) {
                        onSelectionChanged([]);
                      } else {
                        onSelectionChanged([item]);
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    // NEW: Smaller padding for tags
                    padding: EdgeInsets.symmetric(
                        horizontal: isTag ? 12.0 : 16.0,
                        vertical: isTag ? 6.0 : 8.0
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: border,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: isTag ? 12.0 : 14.0, // NEW: Smaller text for tags
                          ),
                        ),
                        if (showX) ...[
                          const SizedBox(width: 4.0),
                          Icon(Icons.close, size: isTag ? 14 : 16, color: textColor),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12), // Reduced bottom margin slightly to account for the new dividers
      ],
    );
  }
}