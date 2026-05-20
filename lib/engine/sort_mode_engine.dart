// Location: lib/engine/sort_mode_engine.dart

import '../models/list_item.dart';

/// The active layout state for the list viewport.
enum SortMode {
  types,       // Generic Macro: Shops, Platforms, Assignees
  categories,  // Generic Micro: Aisles, Genres, Statuses
  customFlat,  // 1D Array: Manual Drag & Drop ordering
  az,          // 1D Array: Alphabetical
  za,          // 1D Array: Reverse Alphabetical
}

/// The base Strategy interface.
abstract class SortStrategy {
  /// Transforms raw items into a flattened layout array.
  /// [groupOrder] is an optional array of IDs (e.g., ['target_id', 'costco_id'])
  /// that dictates the sequence of the Section Headers.
  List<dynamic> flatten(List<ListItem> items, {List<String>? groupOrder});
}

// ==========================================
// STRATEGY IMPLEMENTATIONS
// ==========================================

/// Groups by 'Type' (e.g., Shops, Streaming Platforms)
class TypeSortStrategy implements SortStrategy {
  @override
  List<dynamic> flatten(List<ListItem> items, {List<String>? groupOrder}) {
    // 1. Sort items internally by their fractional type index (O(N log N))
    final List<ListItem> sortedItems = List.from(items)
      ..sort((a, b) => a.typeOrder.compareTo(b.typeOrder));

    // 2. Group items by their macro-type (O(N))
    final Map<String, List<ListItem>> grouped = {};
    for (var item in sortedItems) {
      // Normalize empty strings and remap legacy defaults
      String groupKey = item.type.trim();
      if (groupKey.isEmpty || groupKey == 'Generic') {
        groupKey = 'Any';
      }
      grouped.putIfAbsent(groupKey, () => []).add(item);
    }

    // 3. Sort the Section Headers based on User Preference (Target -> Costco)
    List<String> sortedKeys = grouped.keys.toList();
    if (groupOrder != null && groupOrder.isNotEmpty) {
      sortedKeys.sort((a, b) {
        int indexA = groupOrder.indexOf(a);
        int indexB = groupOrder.indexOf(b);

        // If a group is not in the user's preferred list, push it to the bottom
        if (indexA == -1) indexA = 999999;
        if (indexB == -1) indexB = 999999;

        // If both are missing, fallback to alphabetical
        if (indexA == indexB) return a.compareTo(b);
        return indexA.compareTo(indexB);
      });
    } else {
      // Fallback if no user preference exists
      sortedKeys.sort();
    }

    // 4. Flatten into the $120Hz display array (O(N))
    final List<dynamic> flatList = [];
    for (var key in sortedKeys) {
      flatList.add(key);              // The String Section Header
      flatList.addAll(grouped[key]!); // The ListItem Objects
    }

    return flatList;
  }
}

/// Groups by 'Category' (e.g., Aisles, Genres)
class CategorySortStrategy implements SortStrategy {
  @override
  List<dynamic> flatten(List<ListItem> items, {List<String>? groupOrder}) {
    // 1. Sort items internally by their fractional category index
    final List<ListItem> sortedItems = List.from(items)
      ..sort((a, b) => a.categoryOrder.compareTo(b.categoryOrder));

    // 2. Group by category
    final Map<String, List<ListItem>> grouped = {};
    for (var item in sortedItems) {
      // Normalize empty strings and remap legacy defaults
      String groupKey = item.category.trim();
      if (groupKey.isEmpty || groupKey == 'Uncategorized') {
        groupKey = 'Everything Else';
      }
      grouped.putIfAbsent(groupKey, () => []).add(item);
    }

    // 3. Sort the Section Headers based on User Preference (Produce -> Dairy)
    List<String> sortedKeys = grouped.keys.toList();
    if (groupOrder != null && groupOrder.isNotEmpty) {
      sortedKeys.sort((a, b) {
        int indexA = groupOrder.indexOf(a);
        int indexB = groupOrder.indexOf(b);
        if (indexA == -1) indexA = 999999;
        if (indexB == -1) indexB = 999999;
        if (indexA == indexB) return a.compareTo(b);
        return indexA.compareTo(indexB);
      });
    } else {
      sortedKeys.sort();
    }

    // 4. Flatten into display array
    final List<dynamic> flatList = [];
    for (var key in sortedKeys) {
      flatList.add(key);
      flatList.addAll(grouped[key]!);
    }

    return flatList;
  }
}

/// Flattens items alphabetically. Strips out all section headers entirely.
class AlphabeticalSortStrategy implements SortStrategy {
  final bool descending;

  AlphabeticalSortStrategy({this.descending = false});

  @override
  List<dynamic> flatten(List<ListItem> items, {List<String>? groupOrder}) {
    final List<ListItem> sortedItems = List.from(items)
      ..sort((a, b) {
        final comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return descending ? -comparison : comparison;
      });

    // Return purely items. No String headers injected.
    return sortedItems;
  }
}

/// Flattens items using the global custom fractional order. Strips out all section headers.
class CustomFlatSortStrategy implements SortStrategy {
  @override
  List<dynamic> flatten(List<ListItem> items, {List<String>? groupOrder}) {
    final List<ListItem> sortedItems = List.from(items)
      ..sort((a, b) => a.globalCustomOrder.compareTo(b.globalCustomOrder));

    // Return purely items. No String headers injected.
    return sortedItems;
  }
}

// ==========================================
// THE ENGINE CONTEXT
// ==========================================

class SortModeEngine {
  /// Executes the requested strategy.
  /// [groupOrder] is passed from the user's profile settings (e.g., preferred shop route).
  static List<dynamic> execute(
      List<ListItem> items,
      SortMode mode,
      {List<String>? groupOrder}
      ) {
    switch (mode) {
      case SortMode.types:
        return TypeSortStrategy().flatten(items, groupOrder: groupOrder);
      case SortMode.categories:
        return CategorySortStrategy().flatten(items, groupOrder: groupOrder);
      case SortMode.az:
      // Pass empty list to az/za since they don't have headers
        return AlphabeticalSortStrategy(descending: false).flatten(items);
      case SortMode.za:
        return AlphabeticalSortStrategy(descending: true).flatten(items);
      case SortMode.customFlat:
        return CustomFlatSortStrategy().flatten(items);
    }
  }
}