// Location: lib/providers/list_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/list_item.dart';
import '../theme/app_constants.dart';
import '../engine/sticky_header_engine.dart';
import '../engine/sort_mode_engine.dart';

class ListProvider extends ChangeNotifier {
  double _viewportWidth = 0.0;

  // --- SORTING STATE & PREFERENCES ---
  SortMode _currentSortMode = SortMode.categories;

  List<String> preferredTypeOrder = [];
  List<String> preferredCategoryOrder = [];

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

  // --- Edit Mode & Selection State ---
  final Set<String> _selectedItemIds = {};
  final Map<String, int> _draftQuantities = {};

  // --- AGILE DICTIONARY STATE ---
  // In the future, this will be fetched from the Parent List object.
  final String currentListType = 'Shopping';

  final Map<String, List<String>> _globalCategories = {
    'Shopping': ['Produce', 'Dairy', 'Bakery', 'Pantry', 'Meat', 'Household', 'Frozen', 'Snacks'],
  };
  final Map<String, List<String>> _globalStores = {
    'Shopping': ['Costco', 'Target', 'Walmart', 'Aldi', 'Trader Joes', 'Jewel-Osco'],
  };
  final Map<String, List<String>> _globalTags = {
    'Shopping': ['vegan', 'urgent', 'bulk', 'sale', 'low sodium', 'organic'],
  };

  // Helper to merge user history with global defaults
  List<String> _getMergedDictionary(String propertyType, List<String> globalDefaults) {
    final Set<String> userHistory = {};
    for (var item in _items) {
      if (!item.isDeleted) {
        if (propertyType == 'category' && item.category.isNotEmpty && item.category != 'Everything Else') userHistory.add(item.category);
        if (propertyType == 'type' && item.type.isNotEmpty && item.type != 'Any') userHistory.add(item.type);
        if (propertyType == 'tags') userHistory.addAll(item.attributeRows);
      }
    }

    // Combine history first, then pad with global defaults, keeping unique values
    final List<String> mergedList = userHistory.toList();
    for (var defaultVal in globalDefaults) {
      if (!mergedList.contains(defaultVal)) mergedList.add(defaultVal);
    }
    return mergedList.take(10).toList(); // Limit to top 10 badges for quick tapping
  }

  List<String> get activeCategoryDictionary => _getMergedDictionary('category', _globalCategories[currentListType] ?? []);
  List<String> get activeStoreDictionary => _getMergedDictionary('type', _globalStores[currentListType] ?? []);
  List<String> get activeTagDictionary => _getMergedDictionary('tags', _globalTags[currentListType] ?? []);

  ListProvider() {
    _buildDisplayList();
    runDataMigration(); // Fixes legacy 0.0 ties immediately on startup
  }

  // --- UPGRADED MIGRATION: Detects ANY duplicates or zeroes and heals them ---
  // --- 1. ISOLATED DATA MIGRATION ---
  // Safely assigns perfect 100.0 spacing to all three dimensions independently!
  void runDataMigration() {
    bool needsMigration = _items.any((item) =>
    item.categoryOrder < 100.0 ||
        item.typeOrder < 100.0 ||
        item.globalCustomOrder < 100.0);

    if (!needsMigration) return;

    // Migrate Category Dimension
    _items.sort((a, b) => a.categoryOrder.compareTo(b.categoryOrder));
    for(int i=0; i<_items.length; i++) {
      _items[i] = _items[i].copyWith(categoryOrder: (i+1) * 100.0);
    }

    // Migrate Type (Store) Dimension
    _items.sort((a, b) => a.typeOrder.compareTo(b.typeOrder));
    for(int i=0; i<_items.length; i++) {
      _items[i] = _items[i].copyWith(typeOrder: (i+1) * 100.0);
    }

    // Migrate Flat/Custom Dimension
    _items.sort((a, b) => a.globalCustomOrder.compareTo(b.globalCustomOrder));
    for(int i=0; i<_items.length; i++) {
      _items[i] = _items[i].copyWith(globalCustomOrder: (i+1) * 100.0);
    }

    _buildDisplayList();
    notifyListeners();
  }

  Set<String> get selectedItemIds => _selectedItemIds;
  bool get isEditMode => _selectedItemIds.isNotEmpty;

  void toggleSelection(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
      _draftQuantities.remove(id);
    } else {
      _selectedItemIds.add(id);
      final item = _items.firstWhere((element) => element.id == id);
      _draftQuantities[id] = item.quantity;
    }
    _isFullEditRequested = false;
    notifyListeners();
  }



  int getDraftQuantity(String id) => _draftQuantities[id] ?? 1;

  void updateDraftQuantity(String id, int delta) {
    if (!_draftQuantities.containsKey(id)) return;
    final newQty = _draftQuantities[id]! + delta;
    if (newQty > 0) {
      _draftQuantities[id] = newQty;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedItemIds.clear();
    _draftQuantities.clear();
    _isFullEditRequested = false;
    _isMultiSelectMode = false;
    notifyListeners();
  }

  void commitEdits() {
    for (String id in _selectedItemIds) {
      final rawIndex = _items.indexWhere((item) => item.id == id);
      if (rawIndex != -1 && _draftQuantities.containsKey(id)) {
        _items[rawIndex] = _items[rawIndex].copyWith(quantity: _draftQuantities[id]!);
      }
    }
    clearSelection();
  }

  // --- 4. CONTEXT-ISOLATED NATIVE REORDER MATH ---
  void executeNativeReorder(int oldIndex, int newIndex) {
    if (_currentSortMode == SortMode.az) return;

    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final virtualList = List.of(displayList);
    final draggedItem = virtualList.removeAt(oldIndex) as ListItem;
    virtualList.insert(newIndex, draggedItem);

    String newCategory = draggedItem.category;
    String newType = draggedItem.type;

    final immediateAbove = newIndex > 0 ? virtualList[newIndex - 1] : null;
    final immediateBelow = newIndex < virtualList.length - 1 ? virtualList[newIndex + 1] : null;

    if (immediateAbove is String) {
      if (_currentSortMode == SortMode.categories) newCategory = immediateAbove;
      if (_currentSortMode == SortMode.types) newType = immediateAbove;
    } else if (immediateAbove is ListItem) {
      if (_currentSortMode == SortMode.categories) newCategory = immediateAbove.category;
      if (_currentSortMode == SortMode.types) newType = immediateAbove.type;
    } else if (immediateAbove == null && immediateBelow is String) {
      if (_currentSortMode == SortMode.categories) newCategory = immediateBelow;
      if (_currentSortMode == SortMode.types) newType = immediateBelow;
    } else if (immediateAbove == null && immediateBelow is ListItem) {
      if (_currentSortMode == SortMode.categories) newCategory = immediateBelow.category;
      if (_currentSortMode == SortMode.types) newType = immediateBelow.type;
    }

    // THE FIX: "Header Walls". Stop searching the moment we hit a section boundary!
    ListItem? nearestAbove;
    for (int i = newIndex - 1; i >= 0; i--) {
      if (virtualList[i] is String) break; // Wall hit! We are at the absolute top of this section.
      if (virtualList[i] is ListItem) { nearestAbove = virtualList[i] as ListItem; break; }
    }

    ListItem? nearestBelow;
    for (int i = newIndex + 1; i < virtualList.length; i++) {
      if (virtualList[i] is String) break; // Wall hit! We are at the absolute bottom of this section.
      if (virtualList[i] is ListItem) { nearestBelow = virtualList[i] as ListItem; break; }
    }

    double newOrder = 0.0;
    if (nearestAbove != null && nearestBelow != null) {
      newOrder = (_getActiveOrder(nearestAbove) + _getActiveOrder(nearestBelow)) / 2.0;
    } else if (nearestAbove != null && nearestBelow == null) {
      newOrder = _getActiveOrder(nearestAbove) + 100.0;
    } else if (nearestAbove == null && nearestBelow != null) {
      newOrder = _getActiveOrder(nearestBelow) / 2.0;
    } else {
      newOrder = 100.0;
    }

    final rawIndex = _items.indexWhere((i) => i.id == draggedItem.id);
    if (rawIndex != -1) {
      _items[rawIndex] = _items[rawIndex].copyWith(
        category: newCategory,
        type: newType,
        categoryOrder: _currentSortMode == SortMode.categories ? newOrder : _items[rawIndex].categoryOrder,
        typeOrder: _currentSortMode == SortMode.types ? newOrder : _items[rawIndex].typeOrder,
        globalCustomOrder: _currentSortMode == SortMode.customFlat ? newOrder : _items[rawIndex].globalCustomOrder,
      );

      _buildDisplayList();
      notifyListeners();
    }
  }

  SortMode get currentSortMode => _currentSortMode;

  List<ListItem> get activeItems {
    return _items.where((item) => !item.isDeleted && !item.isCompleted).toList();
  }

  void setSortMode(SortMode newMode) {
    if (_currentSortMode != newMode) {
      _currentSortMode = newMode;
      _buildDisplayList();
      notifyListeners();
    }
  }

  String? _flashItemId;
  String? get flashItemId => _flashItemId;
  Timer? _flashTimer;

  double? getOffsetForItem(String id) {
    final index = displayList.indexWhere((element) => element is ListItem && element.id == id);
    if (index != -1 && index < cumulativeYOffsets.length) {
      return cumulativeYOffsets[index];
    }
    return null;
  }

  // --- 2. MULTI-DIMENSIONAL ADD ITEM ---
  // --- MULTI-DIMENSIONAL ADD ITEM (SECTION AWARE) ---
  void addItem(String title, List<String> attributes, String type, String category, int newQty, String newUnit) {
    final safeType = type.trim().isEmpty ? "Any" : type.trim();
    final safeCategory = category.trim().isEmpty ? "Everything Else" : category.trim();

    double maxCat = 0.0, maxType = 0.0, maxGlobal = 0.0;

    for (var item in _items) {
      // THE FIX: Only compare numbers against items in the SAME section!
      if (item.category == safeCategory && item.categoryOrder > maxCat) maxCat = item.categoryOrder;
      if (item.type == safeType && item.typeOrder > maxType) maxType = item.typeOrder;
      if (item.globalCustomOrder > maxGlobal) maxGlobal = item.globalCustomOrder;
    }

    final newItem = ListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      attributeRows: attributes,
      type: safeType,
      category: safeCategory,
      categoryOrder: maxCat + 100.0, // Safely drops it at the bottom of its assigned Category
      typeOrder: maxType + 100.0,    // Safely drops it at the bottom of its assigned Store
      globalCustomOrder: maxGlobal + 100.0,
    );

    _items.add(newItem);
    _recalculateWraps();
    _buildDisplayList();

    _flashItemId = newItem.id;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 4), () {
      _flashItemId = null;
      notifyListeners();
    });

    notifyListeners();
  }

  // --- FLUID SHEET & SELECTION STATE ---
  bool _isFullEditRequested = false;
  bool get isFullEditRequested => _isFullEditRequested;

  bool _isMultiSelectMode = false;
  bool get isMultiSelectMode => _isMultiSelectMode;

  void setFullEditRequest(bool requested) {
    if (_isFullEditRequested != requested) {
      _isFullEditRequested = requested;
      notifyListeners();
    }
  }

  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    if (!_isMultiSelectMode) {
      clearSelection();
    }
    notifyListeners();
  }

  // NEW: Exclusive Single Selection
  void selectSingleItem(String id) {
    _selectedItemIds.clear();
    _draftQuantities.clear();
    _selectedItemIds.add(id);

    final item = _items.firstWhere((element) => element.id == id);
    _draftQuantities[id] = item.quantity;

    _isFullEditRequested = false;
    _isMultiSelectMode = false; // Ensure we aren't stuck in batch mode
    notifyListeners();
  }





  // --- BATCH ACTIONS ---
  List<String> checkSelectedItems() {
    final checkedIds = List<String>.from(_selectedItemIds);
    for (String id in checkedIds) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) _items[index] = _items[index].copyWith(isCompleted: true);
    }
    clearSelection();
    _buildDisplayList();
    return checkedIds; // Return IDs for the Undo Toast
  }

  List<String> deleteSelectedItems() {
    final deletedIds = List<String>.from(_selectedItemIds);
    for (String id in deletedIds) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) _items[index] = _items[index].copyWith(isDeleted: true);
    }
    clearSelection();
    _buildDisplayList();
    return deletedIds; // Return IDs for the Undo Toast
  }

  // --- UNDO ENGINE ---
  void restoreItems(List<String> ids) {
    bool changed = false;
    for (String id in ids) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        // Flipping flags back to false natively restores their exact position in the math engine
        _items[index] = _items[index].copyWith(isDeleted: false, isCompleted: false);
        changed = true;
      }
    }
    if (changed) {
      _buildDisplayList();
      notifyListeners();
    }
  }

  void copySelectedItems() {
    List<ListItem> newItems = [];
    for (String id in _selectedItemIds) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        final original = _items[index];
        newItems.add(original.copyWith(
          id: DateTime.now().microsecondsSinceEpoch.toString() + original.id,
          title: '${original.title} (Copy)',
          globalCustomOrder: original.globalCustomOrder + 10.0, // Slight offset
        ));
      }
    }
    _items.addAll(newItems);
    clearSelection();
    _buildDisplayList();
  }

  // --- MULTI-DIMENSIONAL EDIT ITEM (SECTION AWARE) ---
  // --- MULTI-DIMENSIONAL EDIT ITEM (SECTION AWARE) ---
  void editItem(String id, String newTitle, List<String> newAttributes, String type, String category, int newQty, String newUnit) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final oldItem = _items[index];
      final safeType = type.trim().isEmpty ? "Any" : type.trim();
      final safeCategory = category.trim().isEmpty ? "Everything Else" : category.trim();

      double newCatOrder = oldItem.categoryOrder;
      double newTypeOrder = oldItem.typeOrder;

      // Calculate a new order if the category changed
      if (oldItem.category != safeCategory) {
        double maxCat = 0.0;
        for (var i in _items) {
          if (i.category == safeCategory && i.categoryOrder > maxCat) maxCat = i.categoryOrder;
        }
        newCatOrder = maxCat + 100.0;
      }

      // Calculate a new order if the Store (Type) changed
      if (oldItem.type != safeType) {
        double maxType = 0.0;
        for (var i in _items) {
          if (i.type == safeType && i.typeOrder > maxType) maxType = i.typeOrder;
        }
        newTypeOrder = maxType + 100.0;
      }

      // THE FIX: Explicitly assign newQty and newUnit to the database write!
      _items[index] = oldItem.copyWith(
        title: newTitle,
        attributeRows: newAttributes,
        type: safeType,
        category: safeCategory,
        quantity: newQty,
        unit: newUnit,
        categoryOrder: newCatOrder,
        typeOrder: newTypeOrder,
      );

      _recalculateWraps();
      _buildDisplayList();
      notifyListeners();
    }
  }

  void updateQuantity(String id, int delta) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final newQuantity = (_items[index].quantity + delta).clamp(1, 99);
      if (_items[index].quantity != newQuantity) {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
        notifyListeners();
      }
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

    final double titleAvailableWidth = _viewportWidth -
        (AppConstants.horizontalPadding * 2) -
        AppConstants.leadingBlockWidth -
        (AppConstants.interElementGap * 2) -
        AppConstants.trailingBlockWidth;

    final double tagAvailableWidth = _viewportWidth -
        (AppConstants.horizontalPadding * 2) -
        AppConstants.leadingBlockWidth -
        AppConstants.interElementGap;

    if (titleAvailableWidth <= 0) return;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      final TextPainter tp = TextPainter(
        text: TextSpan(
            text: item.title,
            style: const TextStyle(fontSize: AppConstants.titleFontSize, height: AppConstants.titleLineHeight)
        ),
        textDirection: TextDirection.ltr,
        maxLines: AppConstants.maxTitleLines,
      )..layout(maxWidth: titleAvailableWidth);

      final int lineCount = tp.didExceedMaxLines
          ? AppConstants.maxTitleLines
          : tp.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: item.title.length)).isNotEmpty
          ? (tp.height / (AppConstants.titleFontSize * AppConstants.titleLineHeight)).round()
          : 1;

      final int calculatedNWrap = (lineCount - 1).clamp(0, 5);

      int calculatedTagRows = 0;
      if (item.attributeRows.isNotEmpty) {
        double currentLineWidth = 0.0;
        calculatedTagRows = 1;
        const double wrapSpacing = 8.0;

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

          final double actualBadgeWidth = tagTp.width +
              (AppConstants.badgeHorizontalPadding * 2) +
              AppConstants.badgeIconSize +
              AppConstants.badgeIconGap;

          if (currentLineWidth == 0.0) {
            currentLineWidth = actualBadgeWidth;
          } else if (currentLineWidth + wrapSpacing + actualBadgeWidth > tagAvailableWidth) {
            calculatedTagRows++;
            currentLineWidth = actualBadgeWidth;
          } else {
            currentLineWidth += wrapSpacing + actualBadgeWidth;
          }
        }
      }

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

  // --- UPGRADED BUILDER: Intercepts the SortModeEngine to force Custom Math ---
  void _buildDisplayList() {
    List<String>? activeGroupOrder;
    if (_currentSortMode == SortMode.types) activeGroupOrder = preferredTypeOrder;
    else if (_currentSortMode == SortMode.categories) activeGroupOrder = preferredCategoryOrder;

    final flattenedArray = SortModeEngine.execute(
      activeItems,
      _currentSortMode,
      groupOrder: activeGroupOrder,
    );

    List<dynamic> strictlySortedArray = [];

    if (_currentSortMode != SortMode.az) {
      List<ListItem> currentGroup = [];
      String? currentHeader;

      for (var item in flattenedArray) {
        if (item is String) {
          if (currentHeader != null || currentGroup.isNotEmpty) {
            // THE FIX: Sort the internal blocks strictly by the ACTIVE view's order!
            currentGroup.sort((a, b) {
              if (_currentSortMode == SortMode.categories) return a.categoryOrder.compareTo(b.categoryOrder);
              if (_currentSortMode == SortMode.types) return a.typeOrder.compareTo(b.typeOrder);
              return a.globalCustomOrder.compareTo(b.globalCustomOrder);
            });
            strictlySortedArray.addAll(currentGroup);
            currentGroup.clear();
          }
          currentHeader = item;
          strictlySortedArray.add(item);
        } else if (item is ListItem) {
          currentGroup.add(item);
        }
      }
      if (currentGroup.isNotEmpty) {
        currentGroup.sort((a, b) {
          if (_currentSortMode == SortMode.categories) return a.categoryOrder.compareTo(b.categoryOrder);
          if (_currentSortMode == SortMode.types) return a.typeOrder.compareTo(b.typeOrder);
          return a.globalCustomOrder.compareTo(b.globalCustomOrder);
        });
        strictlySortedArray.addAll(currentGroup);
      }
    } else {
      strictlySortedArray = flattenedArray;
    }

    displayList.clear();
    displayList.addAll(strictlySortedArray);
    _recalculateYOffsets();
  }

  // --- Helper to fetch the correct active sequence number ---
  double _getActiveOrder(ListItem item) {
    if (_currentSortMode == SortMode.categories) return item.categoryOrder;
    if (_currentSortMode == SortMode.types) return item.typeOrder;
    return item.globalCustomOrder;
  }

  void _recalculateYOffsets() {
    cumulativeYOffsets.clear();
    final calculatedOffsets = StickyHeaderEngine.calculateSpatialCache(displayList);
    cumulativeYOffsets.addAll(calculatedOffsets);

    if (cumulativeYOffsets.isNotEmpty) {
      totalListHeight = cumulativeYOffsets.last;
    }
  }

  // --- SINGLE ACTIONS ---
  String toggleCompletion(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isCompleted: !_items[index].isCompleted);
      _buildDisplayList();
      notifyListeners();
    }
    return id; // Return ID for the Undo Toast
  }

  String deleteItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isDeleted: true);
      _buildDisplayList();
      notifyListeners();
    }
    return id; // Return ID for the Undo Toast
  }
}