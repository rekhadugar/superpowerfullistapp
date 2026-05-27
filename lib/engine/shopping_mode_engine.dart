import '../models/list_item.dart';

/// The structured payload that the Shopping Mode UI will render.
class ShoppingModeResult {
  final Map<String, List<ListItem>> mainItemsByCategory;
  final Map<String, List<ListItem>> alsoAvailableByCategory;
  final List<ListItem> excludedItems;

  ShoppingModeResult({
    required this.mainItemsByCategory,
    required this.alsoAvailableByCategory,
    required this.excludedItems,
  });
}

class ShoppingModeEngine {
  /// Scans all active items to generate a unique list of available stores.
  /// This powers the "Where are you shopping?" pre-flight screen.
  static List<String> getAvailableShops(List<ListItem> allShoppingItems) {
    final Set<String> shops = {};
    bool hasAnyItems = false; // NEW: Track if we have generic items

    for (var item in allShoppingItems) {
      if (item.isCompleted || item.isDeleted) continue;

      final String type = item.type.trim();

      // FIXED: Safely identify "Any" items while capturing specific stores
      if (type.toLowerCase() == 'any') {
        hasAnyItems = true;
      } else if (type.isNotEmpty) {
        shops.add(type);
      }

      for (var loc in item.locations) {
        if (loc.trim().isNotEmpty && loc.trim().toLowerCase() != 'any') {
          shops.add(loc.trim());
        }
      }
    }

    final sortedShops = shops.toList()..sort();

    // FIXED: If they have items that can be bought anywhere, give them an "Any" button to start the trip!
    if (hasAnyItems) {
      sortedShops.add('Any');
    }

    return sortedShops;
  }

  /// The Core Aggregation Engine.
  /// Processes all lists, applies the learning heuristics, and builds the UI groupings.
  static ShoppingModeResult process({
    required List<ListItem> allShoppingItems,
    required String activeStore,
  }) {
    final Map<String, List<ListItem>> mainItems = {};
    final Map<String, List<ListItem>> alsoAvailable = {};
    final List<ListItem> excluded = [];

    final String normalizedActive = activeStore.trim().toLowerCase();

    for (var item in allShoppingItems) {
      // 1. Skip items that are already done or deleted
      if (item.isCompleted || item.isDeleted) continue;

      // 2. The Banish Logic (Excluded Items)
      final bool isExcluded = item.excludedLocations
          .map((e) => e.trim().toLowerCase())
          .contains(normalizedActive);

      if (isExcluded) {
        excluded.add(item);
        continue; // Skip further processing for this item
      }

      // 3. The Routing Logic
      final String normalizedType = item.type.trim().toLowerCase();
      final bool isAny = normalizedType == 'any';
      final bool isPrimaryStore = normalizedType == normalizedActive;

      // The Learning Loop: Check if we've bought it here before
      final bool isLearnedStore = item.locations
          .map((e) => e.trim().toLowerCase())
          .contains(normalizedActive);

      if (isPrimaryStore || isAny || isLearnedStore) {
        // BELONGS IN MAIN LIST
        mainItems.putIfAbsent(item.category, () => []).add(item);
      } else {
        // BELONGS IN "ALSO AVAILABLE" (Tagged for a different store)
        alsoAvailable.putIfAbsent(item.category, () => []).add(item);
      }
    }

    // 4. Deterministic Sorting (Alphabetical)
    // To keep the physical shopping trip predictable, we sort the arrays alphabetically.
    for (var list in mainItems.values) {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    for (var list in alsoAvailable.values) {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    excluded.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return ShoppingModeResult(
      mainItemsByCategory: mainItems,
      alsoAvailableByCategory: alsoAvailable,
      excludedItems: excluded,
    );
  }
}