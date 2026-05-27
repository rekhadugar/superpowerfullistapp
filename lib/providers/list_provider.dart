import 'dart:async';
import 'package:flutter/material.dart';
import '../models/list_item.dart';
import '../theme/app_constants.dart';
import '../engine/sticky_header_engine.dart';
import '../engine/sort_mode_engine.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_global_dictionary.dart';

class ListProvider extends ChangeNotifier {
  String? _currentListId;
  double _viewportWidth = 0.0;
  double _textScaleFactor = 1.0;

  // --- CROSS-LIST SHOPPING MODE STATE ---
  final List<ListItem> _shoppingModeItems = [];
  final Map<String, String> _itemOriginMap = {}; // Maps itemId -> listId
  String? _activeShoppingStore;

  bool _isLoadingShoppingMode = true;

  List<ListItem> get shoppingModeItems => _shoppingModeItems;
  String? get activeShoppingStore => _activeShoppingStore;
  bool get isLoadingShoppingMode => _isLoadingShoppingMode;

  // --- SORTING STATE & PREFERENCES ---
  SortMode _currentSortMode = SortMode.categories;

  List<String> preferredTypeOrder = [];
  List<String> preferredCategoryOrder = [];

  List<ListItem> _items = [];

  // --- GESTURE & SPATIAL CACHE STATE ---
  final ValueNotifier<String?> openSwipeItemId = ValueNotifier(null);

  // ACTIVE LIST CACHE
  final List<dynamic> displayList = [];
  final List<double> cumulativeYOffsets = [];
  double totalListHeight = 0.0;

  // COMPLETED LIST CACHE
  final List<dynamic> checkedDisplayList = [];
  final List<double> checkedCumulativeYOffsets = [];

  // --- SEPARATED INTERACTION STATE ---
  final Set<String> _selectedItemIds = {};
  String? _editItemId;

  Set<String> get selectedItemIds => _selectedItemIds;
  String? get editItemId => _editItemId;

  bool get isBatchModeActive => _selectedItemIds.isNotEmpty;

  void setEditItem(String? id) {
    _editItemId = id;
    if (id != null) {
      _selectedItemIds.clear();
    }
    notifyListeners();
  }

  void toggleSelection(String id) {
    _editItemId = null;
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
    } else {
      _selectedItemIds.add(id);
    }
    notifyListeners();
  }

  void clearAllInteractions() {
    _selectedItemIds.clear();
    _editItemId = null;
    openSwipeItemId.value = null;
    notifyListeners();
  }

  final Map<String, int> _draftQuantities = {};
  final String currentListType = 'Shopping';

  // --- AGILE DICTIONARY STATE ---
  List<String> get activeCategoryDictionary {
    return _getMergedDictionary()
        .map((item) => item.category)
        .where((c) => c.isNotEmpty && c != 'Everything Else')
        .toSet()
        .toList()..sort();
  }

  List<String> get activeStoreDictionary {
    return _getMergedDictionary()
        .map((item) => item.store)
        .where((s) => s.isNotEmpty && s != 'Any')
        .toSet()
        .toList()..sort();
  }

  List<String> get activeTagDictionary {
    return _getMergedDictionary()
        .expand((item) => item.tags)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()..sort();
  }

  ListProvider() {
    _buildDisplayList();
    _buildCheckedDisplayList();
    runDataMigration();
  }

  // --- LOCAL ISOLATED STORAGE ENGINE ---
  Future<void> loadItemsForList(String listId) async {
    if (_currentListId == listId) return;

    _currentListId = listId;
    final prefs = await SharedPreferences.getInstance();

    // FIXED: Always load the Global Settings on cold boot!
    final storesJson = prefs.getString('global_stores');
    if (storesJson != null) {
      final List<dynamic> decoded = jsonDecode(storesJson);
      preferredTypeOrder = decoded.map((m) => m['name'].toString()).toList();
    } else {
      preferredTypeOrder = ['Any', 'Costco', 'Target', 'Walmart', 'Trader Joe\'s'];
    }

    final catJson = prefs.getString('global_categories');
    if (catJson != null) {
      final List<dynamic> decoded = jsonDecode(catJson);
      preferredCategoryOrder = decoded.map((m) => m['name'].toString()).toList();
    } else {
      preferredCategoryOrder = ['Produce', 'Dairy', 'Bakery', 'Everything Else'];
    }

    // Load Items
    final String? itemsJson = prefs.getString('items_$_currentListId');
    if (itemsJson != null) {
      final List<dynamic> decoded = jsonDecode(itemsJson);
      _items = decoded.map((map) => ListItem.fromMap(map)).toList();
    } else {
      _items = [];
    }

    await _runDailyPurge(prefs);

    _recalculateWraps();
    _buildDisplayList();
    _buildCheckedDisplayList();
    notifyListeners();
  }

  Future<void> _saveItemsToStorage() async {
    if (_currentListId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_items.map((i) => i.toMap()).toList());
    await prefs.setString('items_$_currentListId', encoded);
  }

  Future<void> _runDailyPurge(SharedPreferences prefs) async {
    final lastPurgeStr = prefs.getString('last_purge_date_$_currentListId');
    final now = DateTime.now();
    bool shouldPurge = false;

    if (lastPurgeStr == null) {
      shouldPurge = true;
    } else {
      final lastPurge = DateTime.parse(lastPurgeStr);
      if (now.difference(lastPurge).inHours >= 24) {
        shouldPurge = true;
      }
    }

    if (shouldPurge) {
      final initialCount = _items.length;
      _items.removeWhere((item) => item.isDeleted);

      if (_items.length < initialCount) {
        final String encoded = jsonEncode(_items.map((i) => i.toMap()).toList());
        await prefs.setString('items_$_currentListId', encoded);
      }

      await prefs.setString('last_purge_date_$_currentListId', now.toIso8601String());
    }
  }

  // --- 1. ISOLATED DATA MIGRATION ---
  void runDataMigration() {
    bool needsMigration = _items.any((item) =>
    item.categoryOrder < 100.0 ||
        item.typeOrder < 100.0 ||
        item.globalCustomOrder < 100.0);

    if (!needsMigration) return;

    _items.sort((a, b) => a.categoryOrder.compareTo(b.categoryOrder));
    for(int i=0; i<_items.length; i++) {
      _items[i] = _items[i].copyWith(categoryOrder: (i+1) * 100.0);
    }

    _items.sort((a, b) => a.typeOrder.compareTo(b.typeOrder));
    for(int i=0; i<_items.length; i++) {
      _items[i] = _items[i].copyWith(typeOrder: (i+1) * 100.0);
    }

    _items.sort((a, b) => a.globalCustomOrder.compareTo(b.globalCustomOrder));
    for(int i=0; i<_items.length; i++) {
      _items[i] = _items[i].copyWith(globalCustomOrder: (i+1) * 100.0);
    }

    _buildDisplayList();
    _buildCheckedDisplayList();
    _saveItemsToStorage();
    notifyListeners();
  }

  bool get isEditMode => _selectedItemIds.isNotEmpty;

  int getDraftQuantity(String id) => _draftQuantities[id] ?? 0;

  void updateDraftQuantity(String id, int delta) {
    if (!_draftQuantities.containsKey(id)) return;
    final newQty = _draftQuantities[id]! + delta;
    if (newQty >= 0) {
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
    bool changed = false;
    for (String id in _selectedItemIds) {
      final rawIndex = _items.indexWhere((item) => item.id == id);
      if (rawIndex != -1 && _draftQuantities.containsKey(id)) {
        _items[rawIndex] = _items[rawIndex].copyWith(quantity: _draftQuantities[id]!);
        changed = true;
      }
    }
    if (changed) _saveItemsToStorage();
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

    ListItem? nearestAbove;
    for (int i = newIndex - 1; i >= 0; i--) {
      if (virtualList[i] is String) break;
      if (virtualList[i] is ListItem) { nearestAbove = virtualList[i] as ListItem; break; }
    }

    ListItem? nearestBelow;
    for (int i = newIndex + 1; i < virtualList.length; i++) {
      if (virtualList[i] is String) break;
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
      _saveItemsToStorage();
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

  void addItem(String title, List<String> attributes, String type, String category, int newQty, String newUnit) {
    final safeType = type.trim().isEmpty ? "Any" : type.trim();
    final safeCategory = category.trim().isEmpty ? "Everything Else" : category.trim();

    final sortedNewTags = List<String>.from(attributes)..sort();
    final newTagString = sortedNewTags.join(",");

    final exactMatchIndex = _items.indexWhere((item) {
      if (item.isDeleted || item.isCompleted) return false;
      if (item.title.trim().toLowerCase() != title.trim().toLowerCase()) return false;
      if (item.category != safeCategory) return false;
      if (item.type != safeType) return false;
      final itemTags = List<String>.from(item.attributeRows)..sort();
      return itemTags.join(",") == newTagString;
    });

    if (exactMatchIndex != -1) {
      final existingItem = _items[exactMatchIndex];
      _items[exactMatchIndex] = existingItem.copyWith(
        quantity: (existingItem.quantity + newQty).clamp(0, 99),
        unit: newUnit,
      );
      _recalculateWraps();
      _buildDisplayList();
      _saveItemsToStorage();
      triggerSequentialFlash(existingItem.id);
      notifyListeners();
      return;
    }

    double maxCat = 0.0, maxType = 0.0, maxGlobal = 0.0;

    for (var item in _items) {
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
      categoryOrder: maxCat + 100.0,
      typeOrder: maxType + 100.0,
      globalCustomOrder: maxGlobal + 100.0,
    );

    _items.add(newItem);
    _recalculateWraps();
    _buildDisplayList();
    _buildCheckedDisplayList();
    _saveItemsToStorage();

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

  bool _isCompactView = false;
  bool get isCompactView => _isCompactView;

  void toggleCompactView() {
    _isCompactView = !_isCompactView;
    notifyListeners();
  }

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

  void selectSingleItem(String id) {
    _selectedItemIds.clear();
    _draftQuantities.clear();
    _selectedItemIds.add(id);

    final item = _items.firstWhere((element) => element.id == id);
    _draftQuantities[id] = item.quantity;

    _isFullEditRequested = false;
    _isMultiSelectMode = false;
    notifyListeners();
  }

  String _generateVariantKey(String title, String category, String store, List<String> tags) {
    final sortedTags = List<String>.from(tags)..sort();
    return '${title.toLowerCase().trim()}|${category.trim()}|${store.trim()}|${sortedTags.join(",")}';
  }

  bool isActiveVariant(String title, String category, String store, List<String> tags) {
    final targetKey = _generateVariantKey(title, category, store, tags);
    return _items.any((item) =>
    !item.isDeleted &&
        !item.isCompleted &&
        _generateVariantKey(item.title, item.category, item.type, item.attributeRows) == targetKey
    );
  }

  List<SmartItem> _getMergedDictionary() {
    final Map<String, SmartItem> merged = {};
    final Map<String, int> frequency = {};
    final Map<String, int> recency = {};

    for (var item in MockDictionary.globalItems) {
      final key = _generateVariantKey(item.title, item.category, item.store, item.tags);
      merged[key] = item;
      frequency[key] = 0;
      recency[key] = 0;
    }

    int timeIndex = 0;
    for (var item in _items) {
      if (item.isDeleted) continue;

      final key = _generateVariantKey(item.title, item.category, item.type, item.attributeRows);
      merged[key] = SmartItem(
        title: item.title,
        category: item.category,
        store: item.type,
        unit: item.unit,
        tags: item.attributeRows,
      );
      frequency[key] = (frequency[key] ?? 0) + 1;
      recency[key] = timeIndex++;
    }

    final sortedItems = merged.values.toList();
    sortedItems.sort((a, b) {
      final keyA = _generateVariantKey(a.title, a.category, a.store, a.tags);
      final keyB = _generateVariantKey(b.title, b.category, b.store, b.tags);
      final freqA = frequency[keyA] ?? 0;
      final freqB = frequency[keyB] ?? 0;

      if (freqA != freqB) return freqB.compareTo(freqA);

      final recA = recency[keyA] ?? 0;
      final recB = recency[keyB] ?? 0;
      return recB.compareTo(recA);
    });

    return sortedItems;
  }

  List<SmartItem> searchSmartDictionary(String query) {
    final allItems = _getMergedDictionary();

    if (query.trim().isEmpty) {
      return allItems
          .where((item) => !isActiveVariant(item.title, item.category, item.store, item.tags))
          .take(5)
          .toList();
    }

    final q = query.toLowerCase().trim();
    return allItems
        .where((item) => item.title.toLowerCase().contains(q))
        .toList();
  }

  SmartItem? getMostPopularVariant(String title) {
    final allItems = _getMergedDictionary();
    final q = title.toLowerCase().trim();
    try {
      return allItems.firstWhere((item) => item.title.toLowerCase() == q);
    } catch (e) {
      return null;
    }
  }

  void triggerSequentialFlash(String itemId) {
    Future.delayed(const Duration(milliseconds: 350), () {
      _flashItemId = itemId;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_flashItemId == itemId) {
          _flashItemId = null;
          notifyListeners();
        }
      });
    });
  }

  // --- BATCH ACTIONS ---
  void checkAllActiveItems() {
    bool changed = false;
    for (int i = 0; i < _items.length; i++) {
      if (!_items[i].isDeleted && !_items[i].isCompleted) {
        _items[i] = _items[i].copyWith(isCompleted: true, completedAt: DateTime.now());
        changed = true;
      }
    }
    if (changed) {
      _buildDisplayList();
      _buildCheckedDisplayList();
      _saveItemsToStorage();
      notifyListeners();
    }
  }

  void deleteCompletedItems() {
    bool changed = false;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isCompleted && !_items[i].isDeleted) {
        _items[i] = _items[i].copyWith(isDeleted: true);
        changed = true;
      }
    }
    if (changed) {
      _buildDisplayList();
      _buildCheckedDisplayList();
      _saveItemsToStorage();
      notifyListeners();
    }
  }

  List<String> checkSelectedItems() {
    final checkedIds = List<String>.from(_selectedItemIds);
    for (String id in checkedIds) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) _items[index] = _items[index].copyWith(isCompleted: true, completedAt: DateTime.now());
    }
    clearSelection();
    _buildDisplayList();
    _buildCheckedDisplayList();
    _saveItemsToStorage();
    return checkedIds;
  }

  List<String> deleteSelectedItems() {
    final deletedIds = List<String>.from(_selectedItemIds);
    for (String id in deletedIds) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) _items[index] = _items[index].copyWith(isDeleted: true);
    }
    clearSelection();
    _buildDisplayList();
    _buildCheckedDisplayList();
    _saveItemsToStorage();
    return deletedIds;
  }

  Future<void> moveSelectedToTargetList(String targetListId) async {
    if (targetListId == _currentListId || _selectedItemIds.isEmpty) return;

    final itemsToMove = _items.where((item) => _selectedItemIds.contains(item.id)).toList();
    if (itemsToMove.isEmpty) return;

    _items.removeWhere((item) => _selectedItemIds.contains(item.id));
    _buildDisplayList();
    _buildCheckedDisplayList();
    await _saveItemsToStorage();

    final prefs = await SharedPreferences.getInstance();
    final String? destJson = prefs.getString('items_$targetListId');
    List<ListItem> destItems = [];

    if (destJson != null) {
      final List<dynamic> decoded = jsonDecode(destJson);
      destItems = decoded.map((map) => ListItem.fromMap(map)).toList();
    }

    destItems.addAll(itemsToMove);
    await prefs.setString('items_$targetListId', jsonEncode(destItems.map((i) => i.toMap()).toList()));

    clearSelection();
    notifyListeners();
  }

  Future<void> copySelectedToTargetList(String targetListId) async {
    if (targetListId == _currentListId || _selectedItemIds.isEmpty) return;

    final itemsToCopy = _items.where((item) => _selectedItemIds.contains(item.id)).toList();
    if (itemsToCopy.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final String? destJson = prefs.getString('items_$targetListId');
    List<ListItem> destItems = [];

    if (destJson != null) {
      final List<dynamic> decoded = jsonDecode(destJson);
      destItems = decoded.map((map) => ListItem.fromMap(map)).toList();
    }

    int timeOffset = 0;
    for (var original in itemsToCopy) {
      destItems.add(original.copyWith(
        id: DateTime.now().microsecondsSinceEpoch.toString() + original.id + timeOffset.toString(),
        globalCustomOrder: original.globalCustomOrder + 10.0,
      ));
      timeOffset++;
    }

    await prefs.setString('items_$targetListId', jsonEncode(destItems.map((i) => i.toMap()).toList()));

    clearSelection();
    notifyListeners();
  }

  void restoreItems(List<String> ids) {
    bool changed = false;
    for (String id in ids) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(
          isDeleted: false,
          isCompleted: false,
          completedAt: null,
        );
        changed = true;
      }
    }
    if (changed) {
      _buildDisplayList();
      _buildCheckedDisplayList();
      _saveItemsToStorage();
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
          globalCustomOrder: original.globalCustomOrder + 10.0,
        ));
      }
    }
    if (newItems.isNotEmpty) {
      _items.addAll(newItems);
      clearSelection();
      _buildDisplayList();
      _buildCheckedDisplayList();
      _saveItemsToStorage();
    }
  }

  void editItem(String id, String newTitle, List<String> newAttributes, String type, String category, int newQty, String newUnit) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final oldItem = _items[index];
      final safeType = type.trim().isEmpty ? "Any" : type.trim();
      final safeCategory = category.trim().isEmpty ? "Everything Else" : category.trim();

      final sortedNewTags = List<String>.from(newAttributes)..sort();
      final newTagString = sortedNewTags.join(",");

      final exactMatchIndex = _items.indexWhere((item) {
        if (item.id == id) return false;
        if (item.isDeleted || item.isCompleted) return false;
        if (item.title.trim().toLowerCase() != newTitle.trim().toLowerCase()) return false;
        if (item.category != safeCategory) return false;
        if (item.type != safeType) return false;
        final itemTags = List<String>.from(item.attributeRows)..sort();
        return itemTags.join(",") == newTagString;
      });

      if (exactMatchIndex != -1) {
        final existingItem = _items[exactMatchIndex];
        _items[exactMatchIndex] = existingItem.copyWith(
          quantity: (existingItem.quantity + newQty).clamp(0, 99),
          unit: newUnit,
        );
        _items.removeAt(index);

        _recalculateWraps();
        _buildDisplayList();
        _buildCheckedDisplayList();
        _saveItemsToStorage();
        triggerSequentialFlash(existingItem.id);
        notifyListeners();
        return;
      }

      double newCatOrder = oldItem.categoryOrder;
      double newTypeOrder = oldItem.typeOrder;

      if (oldItem.category != safeCategory) {
        double maxCat = 0.0;
        for (var i in _items) {
          if (i.category == safeCategory && i.categoryOrder > maxCat) maxCat = i.categoryOrder;
        }
        newCatOrder = maxCat + 100.0;
      }

      if (oldItem.type != safeType) {
        double maxType = 0.0;
        for (var i in _items) {
          if (i.type == safeType && i.typeOrder > maxType) maxType = i.typeOrder;
        }
        newTypeOrder = maxType + 100.0;
      }

      _items[index] = oldItem.copyWith(
        title: newTitle,
        attributeRows: newAttributes,
        type: safeType,
        category: safeCategory,
        quantity: newQty,
        unit: newUnit,
        categoryOrder: newCatOrder,
        typeOrder: newTypeOrder,
        isCompleted: false,
        completedAt: null,
      );

      _recalculateWraps();
      _buildDisplayList();
      _buildCheckedDisplayList();
      _saveItemsToStorage();
      notifyListeners();
    }
  }

  void updateQuantity(String id, int delta) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final newQuantity = (_items[index].quantity + delta).clamp(0, 99);
      if (_items[index].quantity != newQuantity) {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
        _saveItemsToStorage();
        notifyListeners();
      }
    }
  }

  void updateViewportMetrics(double width, double textScaleFactor) {
    bool changed = false;
    if (_viewportWidth != width && width > 0) {
      _viewportWidth = width;
      changed = true;
    }
    if (_textScaleFactor != textScaleFactor && textScaleFactor > 0) {
      _textScaleFactor = textScaleFactor;
      changed = true;
    }

    if (changed) {
      _recalculateWraps();
      _recalculateYOffsets();
      _recalculateCheckedYOffsets();
      notifyListeners();
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
        textScaler: TextScaler.linear(_textScaleFactor),
      )..layout(maxWidth: titleAvailableWidth);

      final int lineCount = tp.didExceedMaxLines
          ? AppConstants.maxTitleLines
          : tp.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: item.title.length)).isNotEmpty
          ? (tp.height / (AppConstants.titleFontSize * AppConstants.titleLineHeight * _textScaleFactor)).round()
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
            textScaler: TextScaler.linear(_textScaleFactor),
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
      _buildCheckedDisplayList();
      notifyListeners();
    }
  }

  void _buildCheckedDisplayList() {
    final checkedItems = _items.where((item) => item.isCompleted && !item.isDeleted).toList();

    checkedItems.sort((a, b) => (b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    checkedDisplayList.clear();
    String? currentHeader;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisYearStart = DateTime(now.year, 1, 1);

    for (var item in checkedItems) {
      final date = item.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final itemDate = DateTime(date.year, date.month, date.day);

      String header = "A Long Time Ago";
      if (itemDate == today) {
        header = "Today";
      } else if (itemDate == yesterday) {
        header = "Yesterday";
      } else if (itemDate.isAfter(thisWeekStart) || itemDate == thisWeekStart) {
        header = "This Week";
      } else if (itemDate.isAfter(thisMonthStart) || itemDate == thisMonthStart) {
        header = "This Month";
      } else if (itemDate.isAfter(thisYearStart) || itemDate == thisYearStart) {
        header = "This Year";
      }

      if (header != currentHeader) {
        checkedDisplayList.add(header);
        currentHeader = header;
      }
      checkedDisplayList.add(item);
    }
    _recalculateCheckedYOffsets();
  }

  void _recalculateCheckedYOffsets() {
    checkedCumulativeYOffsets.clear();
    final calculatedOffsets = StickyHeaderEngine.calculateSpatialCache(
        checkedDisplayList,
        textScaleFactor: _textScaleFactor
    );
    checkedCumulativeYOffsets.addAll(calculatedOffsets);
  }

  // --- SETTINGS BRIDGE: ORPHAN REASSIGNMENT & SORT SYNC ---
  void syncWithGlobalSettings(List<String> activeStores, List<String> activeCategories) {
    bool itemsChanged = false;

    preferredTypeOrder = activeStores;
    preferredCategoryOrder = activeCategories;

    for (int i = 0; i < _items.length; i++) {
      String newType = _items[i].type;
      String newCategory = _items[i].category;
      bool modified = false;

      if (!activeStores.contains(newType)) {
        newType = 'Any';
        modified = true;
      }
      if (!activeCategories.contains(newCategory)) {
        newCategory = 'Everything Else';
        modified = true;
      }

      if (modified) {
        _items[i] = _items[i].copyWith(type: newType, category: newCategory);
        itemsChanged = true;
      }
    }

    if (itemsChanged) {
      _saveItemsToStorage();
    }

    _buildDisplayList();
    _buildCheckedDisplayList();
    notifyListeners();
  }

  // --- FIXED: BULLETPROOF ACTIVE LIST GROUPING ENGINE ---
  void _buildDisplayList() {
    List<dynamic> strictlySortedArray = [];

    // If grouping by Category or Store, bypass the SortModeEngine and enforce Settings Index exactly
    if (_currentSortMode == SortMode.categories || _currentSortMode == SortMode.types) {

      // 1. Bucket the items
      Map<String, List<ListItem>> groups = {};
      for (var item in activeItems) {
        String key = _currentSortMode == SortMode.categories ? item.category : item.type;
        if (!groups.containsKey(key)) groups[key] = [];
        groups[key]!.add(item);
      }

      // 2. Sort the Group Headers based purely on Global Settings Index
      List<String> sortedKeys = groups.keys.toList();
      List<String> referenceOrder = _currentSortMode == SortMode.categories ? preferredCategoryOrder : preferredTypeOrder;

      sortedKeys.sort((a, b) {
        int indexA = referenceOrder.indexWhere((e) => e.toLowerCase() == a.toLowerCase());
        int indexB = referenceOrder.indexWhere((e) => e.toLowerCase() == b.toLowerCase());

        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1; // A is recognized, B is an orphan
        if (indexB != -1) return 1;  // B is recognized, A is an orphan
        return a.compareTo(b);       // Both orphans fallback to alphabetical
      });

      // 3. Assemble the final flattened array
      for (String key in sortedKeys) {
        strictlySortedArray.add(key); // Header String
        List<ListItem> currentGroup = groups[key]!;

        // Sort the individual items *inside* the group
        currentGroup.sort((a, b) {
          if (_currentSortMode == SortMode.categories) return a.categoryOrder.compareTo(b.categoryOrder);
          if (_currentSortMode == SortMode.types) return a.typeOrder.compareTo(b.typeOrder);
          return a.globalCustomOrder.compareTo(b.globalCustomOrder);
        });

        strictlySortedArray.addAll(currentGroup);
      }
    } else {
      // 4. Fallback for A-Z or Custom Flat sorting
      final flattenedArray = SortModeEngine.execute(
        activeItems,
        _currentSortMode,
      );

      if (_currentSortMode != SortMode.az) {
        List<ListItem> currentGroup = [];
        String? currentHeader;

        for (var item in flattenedArray) {
          if (item is String) {
            if (currentHeader != null || currentGroup.isNotEmpty) {
              currentGroup.sort((a, b) => a.globalCustomOrder.compareTo(b.globalCustomOrder));
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
          currentGroup.sort((a, b) => a.globalCustomOrder.compareTo(b.globalCustomOrder));
          strictlySortedArray.addAll(currentGroup);
        }
      } else {
        strictlySortedArray = flattenedArray;
      }
    }

    displayList.clear();
    displayList.addAll(strictlySortedArray);
    _recalculateYOffsets();
  }

  double _getActiveOrder(ListItem item) {
    if (_currentSortMode == SortMode.categories) return item.categoryOrder;
    if (_currentSortMode == SortMode.types) return item.typeOrder;
    return item.globalCustomOrder;
  }

  void _recalculateYOffsets() {
    cumulativeYOffsets.clear();
    final calculatedOffsets = StickyHeaderEngine.calculateSpatialCache(
        displayList,
        textScaleFactor: _textScaleFactor
    );
    cumulativeYOffsets.addAll(calculatedOffsets);

    if (cumulativeYOffsets.isNotEmpty) {
      totalListHeight = cumulativeYOffsets.last;
    }
  }

  // --- SINGLE ACTIONS ---
  String toggleCompletion(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final isNowCompleted = !_items[index].isCompleted;
      _items[index] = _items[index].copyWith(
        isCompleted: isNowCompleted,
        completedAt: isNowCompleted ? DateTime.now() : null,
      );
      _buildDisplayList();
      _buildCheckedDisplayList();
      _saveItemsToStorage();
      notifyListeners();
    }
    return id;
  }

  String deleteItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isDeleted: true);
      _buildDisplayList();
      _buildCheckedDisplayList();
      _saveItemsToStorage();
      notifyListeners();
    }
    return id;
  }

  // ==========================================
  // SHOPPING MODE ENGINE HOOKS
  // ==========================================

  void setShoppingStore(String? store) {
    _activeShoppingStore = store;
    notifyListeners();
  }

  Future<void> initializeShoppingMode(List<dynamic> allMacroLists) async {
    _isLoadingShoppingMode = true;
    notifyListeners();
    _shoppingModeItems.clear();
    _itemOriginMap.clear();
    _activeShoppingStore = null;

    final prefs = await SharedPreferences.getInstance();

    // DEBUG 1: Check total lists
    print('DEBUG: Total MacroLists found: ${allMacroLists.length}');

    final shoppingLists = allMacroLists.where((l) => l.typeId == 'sys_shopping').toList();

    // DEBUG 2: Check how many are actually 'Shopping' lists
    print('DEBUG: Shopping Lists filtered: ${shoppingLists.length}');

    for (var list in shoppingLists) {
      final String? itemsJson = prefs.getString('items_${list.id}');

      // DEBUG 3: Check if the database key is pulling data
      print('DEBUG: Data for list ${list.name} (Key: items_${list.id}): ${itemsJson != null ? "FOUND" : "NULL"}');

      if (itemsJson != null) {
        final List<dynamic> decoded = json.decode(itemsJson);
        for (var itemMap in decoded) {
          final item = ListItem.fromMap(itemMap);
          if (!item.isCompleted && !item.isDeleted) {
            _shoppingModeItems.add(item);
            _itemOriginMap[item.id] = list.id;
          }
        }
      }
    }

    // DEBUG 4: Final item count
    print('DEBUG: Total valid shopping items loaded: ${_shoppingModeItems.length}');

    _isLoadingShoppingMode = false;
    notifyListeners();
  }

  Future<void> _updateOriginListStorage(String itemId, ListItem updatedItem) async {
    final listId = _itemOriginMap[itemId];
    if (listId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString('items_$listId');
    if (itemsJson != null) {
      final List<dynamic> decoded = json.decode(itemsJson);
      final List<ListItem> listItems = decoded.map((m) => ListItem.fromMap(m)).toList();

      final listIndex = listItems.indexWhere((i) => i.id == itemId);
      if (listIndex != -1) {
        listItems[listIndex] = updatedItem;
        await prefs.setString('items_$listId', json.encode(listItems.map((i) => i.toMap()).toList()));
      }
    }

    // Sync active view if the user happens to be on that specific list
    if (_currentListId == listId) {
      final activeIndex = _items.indexWhere((i) => i.id == itemId);
      if (activeIndex != -1) {
        _items[activeIndex] = updatedItem;
        _buildDisplayList();
        _buildCheckedDisplayList();
      }
    }
  }

  Future<void> toggleShoppingItemsCompletion(List<String> itemIds) async {
    for (String itemId in itemIds) {
      final index = _shoppingModeItems.indexWhere((i) => i.id == itemId);
      if (index == -1) continue;

      ListItem item = _shoppingModeItems[index];
      final isNowCompleted = !item.isCompleted;

      // THE LEARNING LOOP: If checking off, learn this location!
      if (isNowCompleted && _activeShoppingStore != null && _activeShoppingStore != 'Any') {
        final currentLocs = List<String>.from(item.locations);
        if (!currentLocs.map((e) => e.toLowerCase()).contains(_activeShoppingStore!.toLowerCase())) {
          currentLocs.add(_activeShoppingStore!);
          item = item.copyWith(locations: currentLocs);
        }
      }

      // Mark completed
      item = item.copyWith(
        isCompleted: isNowCompleted,
        completedAt: isNowCompleted ? DateTime.now() : null,
      );

      _shoppingModeItems[index] = item;
      await _updateOriginListStorage(itemId, item);
    }
    clearSelection(); // Clear multi-select state when done
    notifyListeners();
  }

  Future<void> banishShoppingItems(List<String> itemIds) async {
    if (_activeShoppingStore == null) return;

    for (String itemId in itemIds) {
      final index = _shoppingModeItems.indexWhere((i) => i.id == itemId);
      if (index == -1) continue;

      ListItem item = _shoppingModeItems[index];
      final currentExclusions = List<String>.from(item.excludedLocations);

      if (!currentExclusions.map((e) => e.toLowerCase()).contains(_activeShoppingStore!.toLowerCase())) {
        currentExclusions.add(_activeShoppingStore!);
        item = item.copyWith(excludedLocations: currentExclusions);

        _shoppingModeItems[index] = item;
        await _updateOriginListStorage(itemId, item);
      }
    }
    clearSelection(); // Clear multi-select state when done
    notifyListeners();
  }

  // NEW: Allows the Undo Toast to function properly in Shopping Mode
  Future<void> restoreShoppingItems(List<String> itemIds) async {
    for (String itemId in itemIds) {
      final index = _shoppingModeItems.indexWhere((i) => i.id == itemId);
      if (index == -1) continue;

      ListItem item = _shoppingModeItems[index];
      item = item.copyWith(isCompleted: false, completedAt: null);

      _shoppingModeItems[index] = item;
      await _updateOriginListStorage(itemId, item);
    }
    notifyListeners();
  }
}