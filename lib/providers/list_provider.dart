// Location: lib/providers/list_provider.dart

import 'package:flutter/material.dart';
import '../models/list_item.dart';
import '../theme/app_constants.dart';
import '../engine/sticky_header_engine.dart';
import '../engine/sort_mode_engine.dart'; // IMPORT THE SORT ENGINE

class ListProvider extends ChangeNotifier {
  double _viewportWidth = 0.0;

  // --- SORTING STATE & PREFERENCES ---
  SortMode _currentSortMode = SortMode.categories;

  // These would eventually be loaded from the UserProfile or AppList database document
  List<String> preferredTypeOrder = [];
  List<String> preferredCategoryOrder = [];

  // Added mock categories to support the grouping architecture
  // Location: lib/models/mock_data.dart or directly inside your ListProvider



  final List<ListItem> _items = [
    // --- Costco (Bulk & Groceries) ---
    ListItem(id: 'c1', title: 'Almond Milk (3-Pack)', type: 'Costco', category: 'Dairy', typeOrder: 1.1, categoryOrder: 1.5, globalCustomOrder: 45.0),
    ListItem(id: 'c2', title: 'Avocados (Bag)', type: 'Costco', category: 'Produce', typeOrder: 1.2, categoryOrder: 3.1, globalCustomOrder: 12.0),
    ListItem(id: 'c3', title: 'Croissants (12-Count)', type: 'Costco', category: 'Bakery', typeOrder: 1.3, categoryOrder: 2.2, globalCustomOrder: 8.5),
    ListItem(id: 'c4', title: 'Frozen Chicken Breasts', type: 'Costco', category: 'Frozen', typeOrder: 1.4, categoryOrder: 4.0, globalCustomOrder: 22.1),
    ListItem(id: 'c5', title: 'Kirkland Paper Towels', type: 'Costco', category: 'Household', typeOrder: 1.5, categoryOrder: 5.5, globalCustomOrder: 1.0),
    ListItem(id: 'c6', title: 'Mixed Nuts', type: 'Costco', category: 'Pantry', typeOrder: 1.6, categoryOrder: 6.2, globalCustomOrder: 15.0),
    ListItem(id: 'c7', title: 'Organic Spinach', type: 'Costco', category: 'Produce', typeOrder: 1.7, categoryOrder: 3.2, globalCustomOrder: 13.0),
    ListItem(id: 'c8', title: 'Protein Bars', type: 'Costco', category: 'Snacks', typeOrder: 1.8, categoryOrder: 7.1, globalCustomOrder: 16.5),
    ListItem(id: 'c9', title: 'Rotisserie Chicken', type: 'Costco', category: 'Deli', typeOrder: 1.9, categoryOrder: 8.0, globalCustomOrder: 3.0),
    ListItem(id: 'c10', title: 'Toilet Paper', type: 'Costco', category: 'Household', typeOrder: 2.0, categoryOrder: 5.6, globalCustomOrder: 2.0),

    // --- Target (General, Electronics, Home) ---
    ListItem(id: 't1', title: 'AA Batteries (24-Pack)', type: 'Target', category: 'Electronics', typeOrder: 3.1, categoryOrder: 1.1, globalCustomOrder: 25.0),
    ListItem(id: 't2', title: 'Baby Wipes', type: 'Target', category: 'Baby', typeOrder: 3.2, categoryOrder: 2.1, globalCustomOrder: 5.0),
    ListItem(id: 't3', title: 'Bath Towels', type: 'Target', category: 'Home', typeOrder: 3.3, categoryOrder: 3.1, globalCustomOrder: 33.0),
    ListItem(id: 't4', title: 'Coffee Beans', type: 'Target', category: 'Pantry', typeOrder: 3.4, categoryOrder: 6.3, globalCustomOrder: 14.0),
    ListItem(id: 't5', title: 'Desk Lamp', type: 'Target', category: 'Home', typeOrder: 3.5, categoryOrder: 3.2, globalCustomOrder: 35.0),
    ListItem(id: 't6', title: 'Diapers (Size 4)', type: 'Target', category: 'Baby', typeOrder: 3.6, categoryOrder: 2.2, globalCustomOrder: 4.0),
    ListItem(id: 't7', title: 'Gift Wrapping Paper', type: 'Target', category: 'Seasonal', typeOrder: 3.7, categoryOrder: 9.1, globalCustomOrder: 42.0),
    ListItem(id: 't8', title: 'Hand Soap', type: 'Target', category: 'Personal Care', typeOrder: 3.8, categoryOrder: 10.1, globalCustomOrder: 18.0),
    ListItem(id: 't9', title: 'Nintendo Switch Controller', type: 'Target', category: 'Electronics', typeOrder: 3.9, categoryOrder: 1.2, globalCustomOrder: 50.0),
    ListItem(id: 't10', title: 'Toothpaste', type: 'Target', category: 'Personal Care', typeOrder: 4.0, categoryOrder: 10.2, globalCustomOrder: 19.0),

    // --- Home Depot (Hardware & DIY) ---
    ListItem(id: 'hd1', title: 'Air Filters (20x20x1)', type: 'Home Depot', category: 'Hardware', typeOrder: 5.1, categoryOrder: 1.1, globalCustomOrder: 28.0),
    ListItem(id: 'hd2', title: 'Blue Painter’s Tape', type: 'Home Depot', category: 'Paint', typeOrder: 5.2, categoryOrder: 2.1, globalCustomOrder: 30.0),
    ListItem(id: 'hd3', title: 'Drywall Anchors', type: 'Home Depot', category: 'Hardware', typeOrder: 5.3, categoryOrder: 1.2, globalCustomOrder: 29.0),
    ListItem(id: 'hd4', title: 'Eggshell White Paint (1 Gal)', type: 'Home Depot', category: 'Paint', typeOrder: 5.4, categoryOrder: 2.2, globalCustomOrder: 31.0),
    ListItem(id: 'hd5', title: 'Extension Cord (50ft)', type: 'Home Depot', category: 'Electrical', typeOrder: 5.5, categoryOrder: 3.1, globalCustomOrder: 32.0),
    ListItem(id: 'hd6', title: 'Furnace Filter', type: 'Home Depot', category: 'Hardware', typeOrder: 5.6, categoryOrder: 1.3, globalCustomOrder: 28.5),
    ListItem(id: 'hd7', title: 'Light Bulbs (LED 60W)', type: 'Home Depot', category: 'Electrical', typeOrder: 5.7, categoryOrder: 3.2, globalCustomOrder: 26.0),
    ListItem(id: 'hd8', title: 'Matte Polycrylic Finish', type: 'Home Depot', category: 'Paint', typeOrder: 5.8, categoryOrder: 2.3, globalCustomOrder: 31.5),
    ListItem(id: 'hd9', title: 'Sanding Sponges', type: 'Home Depot', category: 'Hardware', typeOrder: 5.9, categoryOrder: 1.4, globalCustomOrder: 29.5),
    ListItem(id: 'hd10', title: 'Wood Glue', type: 'Home Depot', category: 'Hardware', typeOrder: 6.0, categoryOrder: 1.5, globalCustomOrder: 29.8),

    // --- Panda Express (Restaurants/Takeout) ---
    ListItem(id: 'pe1', title: 'Beijing Beef', type: 'Panda Express', category: 'Entree', typeOrder: 7.1, categoryOrder: 1.1, globalCustomOrder: 48.0),
    ListItem(id: 'pe2', title: 'Chow Mein', type: 'Panda Express', category: 'Side', typeOrder: 7.2, categoryOrder: 2.1, globalCustomOrder: 46.0),
    ListItem(id: 'pe3', title: 'Cream Cheese Rangoons', type: 'Panda Express', category: 'Appetizer', typeOrder: 7.3, categoryOrder: 3.1, globalCustomOrder: 49.0),
    ListItem(id: 'pe4', title: 'Fried Rice', type: 'Panda Express', category: 'Side', typeOrder: 7.4, categoryOrder: 2.2, globalCustomOrder: 46.5),
    ListItem(id: 'pe5', title: 'Kung Pao Chicken', type: 'Panda Express', category: 'Entree', typeOrder: 7.5, categoryOrder: 1.2, globalCustomOrder: 47.0),

    // --- Jewel-Osco / Local Grocery (Standard Groceries) ---
    ListItem(id: 'jo1', title: 'Bananas', type: 'Jewel-Osco', category: 'Produce', typeOrder: 9.1, categoryOrder: 3.3, globalCustomOrder: 9.0),
    ListItem(id: 'jo2', title: 'Black Beans (Canned)', type: 'Jewel-Osco', category: 'Pantry', typeOrder: 9.2, categoryOrder: 6.4, globalCustomOrder: 21.0),
    ListItem(id: 'jo3', title: 'Cheddar Cheese Block', type: 'Jewel-Osco', category: 'Dairy', typeOrder: 9.3, categoryOrder: 1.6, globalCustomOrder: 11.0),
    ListItem(id: 'jo4', title: 'Eggs (Dozen)', type: 'Jewel-Osco', category: 'Dairy', typeOrder: 9.4, categoryOrder: 1.7, globalCustomOrder: 7.0),
    ListItem(id: 'jo5', title: 'Fuji Apples', type: 'Jewel-Osco', category: 'Produce', typeOrder: 9.5, categoryOrder: 3.4, globalCustomOrder: 10.5),
    ListItem(id: 'jo6', title: 'Ground Turkey (1 lb)', type: 'Jewel-Osco', category: 'Meat', typeOrder: 9.6, categoryOrder: 11.1, globalCustomOrder: 23.0),
    ListItem(id: 'jo7', title: 'Olive Oil', type: 'Jewel-Osco', category: 'Pantry', typeOrder: 9.7, categoryOrder: 6.5, globalCustomOrder: 20.0),
    ListItem(id: 'jo8', title: 'Pasta Sauce', type: 'Jewel-Osco', category: 'Pantry', typeOrder: 9.8, categoryOrder: 6.6, globalCustomOrder: 20.5),
    ListItem(id: 'jo9', title: 'Spaghetti Noodles', type: 'Jewel-Osco', category: 'Pantry', typeOrder: 9.9, categoryOrder: 6.7, globalCustomOrder: 20.8),
    ListItem(id: 'jo10', title: 'Whole Milk (Gallon)', type: 'Jewel-Osco', category: 'Dairy', typeOrder: 10.0, categoryOrder: 1.8, globalCustomOrder: 6.0),

    // --- Miscellaneous / Uncategorized ---
    ListItem(id: 'm1', title: 'Dog Food (30lb Bag)', type: 'PetSmart', category: 'Pets', typeOrder: 11.1, categoryOrder: 12.1, globalCustomOrder: 38.0),
    ListItem(id: 'm2', title: 'Cat Litter', type: 'PetSmart', category: 'Pets', typeOrder: 11.2, categoryOrder: 12.2, globalCustomOrder: 39.0),
    ListItem(id: 'm3', title: 'Ibuprofen', type: 'Walgreens', category: 'Pharmacy', typeOrder: 12.1, categoryOrder: 13.1, globalCustomOrder: 24.0),
    ListItem(id: 'm4', title: 'Band-Aids', type: 'Walgreens', category: 'Pharmacy', typeOrder: 12.2, categoryOrder: 13.2, globalCustomOrder: 24.5),
    ListItem(id: 'm5', title: 'Pizza (Alfredo Sauce)', type: 'Papa Johns', category: 'Takeout', typeOrder: 13.1, categoryOrder: 14.1, globalCustomOrder: 45.0),
  ];

  // --- GESTURE & SPATIAL CACHE STATE ---
  final ValueNotifier<String?> openSwipeItemId = ValueNotifier(null);
  final List<double> cumulativeYOffsets = [];
  double totalListHeight = 0.0;
  final List<dynamic> displayList = [];

  ListProvider() {
    _buildDisplayList();
  }

  SortMode get currentSortMode => _currentSortMode;

  List<ListItem> get activeItems {
    final filtered = _items.where((item) => !item.isDeleted && !item.isCompleted).toList();
    // We no longer sort by globalCustomOrder here! The Strategy Engine handles all sorting.
    return filtered;
  }

  // --- ACTIONS ---

  void setSortMode(SortMode newMode) {
    if (_currentSortMode != newMode) {
      _currentSortMode = newMode;
      _buildDisplayList();
      notifyListeners();
    }
  }

  void addItem(String title, List<String> attributes, String type, String category) {
    double newCustomOrder = 1000.0;

    if (_items.isNotEmpty) {
      final double currentMin = _items
          .map((item) => item.globalCustomOrder)
          .reduce((a, b) => a < b ? a : b);
      newCustomOrder = currentMin - 1.0;
    }

    final newItem = ListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      attributeRows: attributes,
      // Pass the new routing parameters, falling back to defaults if left blank
      type: type.trim().isEmpty ? "Any" : type.trim(),
      category: category.trim().isEmpty ? "Everything Else" : category.trim(),
      globalCustomOrder: newCustomOrder,
    );

    _items.add(newItem);

    _recalculateWraps();
    _buildDisplayList();
    notifyListeners();
  }

  void editItem(String id, String newTitle, List<String> newAttributes, String type, String category) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        title: newTitle,
        attributeRows: newAttributes,
        type: type.trim().isEmpty ? "Any" : type.trim(),
        category: category.trim().isEmpty ? "Everything Else" : category.trim(),
      );

      // We must rebuild the display list in case the item moved to a different group
      _recalculateWraps();
      _buildDisplayList();
      notifyListeners();
    }
  }

  void updateViewportWidth(double width) {
    if (_viewportWidth != width && width > 0) {
      _viewportWidth = width;
      _recalculateWraps();
    }
  }

  void _recalculateWraps() {
    bool stateChanged = false;

    final double textWidth = _viewportWidth -
        (AppConstants.horizontalPadding * 2) -
        AppConstants.leadingBlockWidth -
        (AppConstants.interElementGap * 2) -
        AppConstants.trailingBlockWidth;

    if (textWidth <= 0) return;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      // --- 1. Measure Title Wraps ---
      final TextPainter tp = TextPainter(
        text: TextSpan(
            text: item.title,
            style: const TextStyle(fontSize: AppConstants.titleFontSize, height: AppConstants.titleLineHeight)
        ),
        textDirection: TextDirection.ltr,
        maxLines: AppConstants.maxTitleLines,
      )..layout(maxWidth: textWidth);

      final int lineCount = tp.didExceedMaxLines
          ? AppConstants.maxTitleLines
          : tp.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: item.title.length)).isNotEmpty
          ? (tp.height / (AppConstants.titleFontSize * AppConstants.titleLineHeight)).round()
          : 1;

      final int calculatedNWrap = (lineCount - 1).clamp(0, 5);

      // --- 2. Measure Tag Badge Wraps ---
      int calculatedTagRows = 0;
      if (item.attributeRows.isNotEmpty) {
        double currentLineWidth = 0.0;
        calculatedTagRows = 1;

        for (String tag in item.attributeRows) {
          final TextPainter tagTp = TextPainter(
            text: TextSpan(
                text: tag,
                style: const TextStyle(
                    fontSize: AppConstants.badgeFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    height: 1.1)),
            textDirection: TextDirection.ltr,
          )..layout();

          // Pixel-perfect physical width of the badge + spacing gap
          final double tagWidth = tagTp.width +
              (AppConstants.badgeHorizontalPadding * 2) +
              AppConstants.badgeIconSize +
              AppConstants.badgeIconGap +
              8.0; // Inter-badge gap

          if (currentLineWidth + tagWidth > textWidth) {
            calculatedTagRows++;
            currentLineWidth = tagWidth; // Start a new line
          } else {
            currentLineWidth += tagWidth; // Add to current line
          }
        }
      }

      // --- 3. Evaluate State Changes ---
      if (item.nWrap != calculatedNWrap || item.nTagRows != calculatedTagRows) {
        _items[i] = item.copyWith(
            nWrap: calculatedNWrap,
            nTagRows: calculatedTagRows
        );
        stateChanged = true;
      }
    }

    if (stateChanged || displayList.isEmpty) {
      _buildDisplayList();
      notifyListeners();
    }
  }

  // ==========================================
  // ARCHITECTURAL BOUNDARY: STRATEGY ENGINE
  // ==========================================

  void _buildDisplayList() {
    // 1. Determine which preference array to pass based on the current mode
    List<String>? activeGroupOrder;
    if (_currentSortMode == SortMode.types) {
      activeGroupOrder = preferredTypeOrder;
    } else if (_currentSortMode == SortMode.categories) {
      activeGroupOrder = preferredCategoryOrder;
    }

    // 2. Delegate list flattening and sorting entirely to the pure Strategy Engine
    final flattenedArray = SortModeEngine.execute(
      activeItems,
      _currentSortMode,
      groupOrder: activeGroupOrder,
    );

    // 3. Update state
    displayList.clear();
    displayList.addAll(flattenedArray);

    // 4. Rebuild the Spatial Cache
    _recalculateYOffsets();
  }

  void _recalculateYOffsets() {
    cumulativeYOffsets.clear();
    final calculatedOffsets = StickyHeaderEngine.calculateSpatialCache(displayList);
    cumulativeYOffsets.addAll(calculatedOffsets);

    if (cumulativeYOffsets.isNotEmpty) {
      totalListHeight = cumulativeYOffsets.last;
    }
  }

  void toggleCompletion(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isCompleted: !_items[index].isCompleted);
      // Rebuild the flat list when an item is removed
      _buildDisplayList();
      notifyListeners();
    }
  }

  void deleteItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isDeleted: true);
      // Rebuild the flat list when an item is removed
      _buildDisplayList();
      notifyListeners();
    }
  }
}