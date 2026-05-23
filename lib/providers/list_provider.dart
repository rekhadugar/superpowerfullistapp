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
  String? _currentListId; // Tracks the active query scope
  double _viewportWidth = 0.0;
  double _textScaleFactor = 1.0;

  // --- SORTING STATE & PREFERENCES ---
  SortMode _currentSortMode = SortMode.categories;

  List<String> preferredTypeOrder = [];
  List<String> preferredCategoryOrder = [];

  List<ListItem> _items = [];

  // --- GESTURE & SPATIAL CACHE STATE ---
  final ValueNotifier<String?> openSwipeItemId = ValueNotifier(null);
  final List<double> cumulativeYOffsets = [];
  double totalListHeight = 0.0;
  final List<dynamic> displayList = [];

  // --- Edit Mode & Selection State ---
  final Set<String> _selectedItemIds = {};
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
    runDataMigration();
  }

  // --- LOCAL ISOLATED STORAGE ENGINE ---
  Future<void> loadItemsForList(String listId) async {
    if (_currentListId == listId) return;

    _currentListId = listId;
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString('items_$_currentListId');

    if (itemsJson != null) {
      final List<dynamic> decoded = jsonDecode(itemsJson);
      _items = decoded.map((map) => ListItem.fromMap(map)).toList();
    } else {
      _items = [];
    }

    _recalculateWraps();
    _buildDisplayList();
    notifyListeners();
  }

  Future<void> _saveItemsToStorage() async {
    if (_currentListId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_items.map((i) => i.toMap()).toList());
    await prefs.setString('items_$_currentListId', encoded);
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
    _saveItemsToStorage();
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

  // --- 2. MULTI-DIMENSIONAL ADD ITEM ---
  void addItem(String title, List<String> attributes, String type, String category, int newQty, String newUnit) {
    final safeType = type.trim().isEmpty ? "Any" : type.trim();
    final safeCategory = category.trim().isEmpty ? "Everything Else" : category.trim();

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

  // ==========================================
  // SMART PREFILL ENGINE
  // ==========================================

  bool isActiveItem(String title) {
    return _items.any((item) =>
    !item.isDeleted &&
        !item.isCompleted &&
        item.title.trim().toLowerCase() == title.trim().toLowerCase()
    );
  }

  String? getActiveItemIdByTitle(String title) {
    try {
      final item = _items.firstWhere((item) =>
      !item.isDeleted &&
          !item.isCompleted &&
          item.title.trim().toLowerCase() == title.trim().toLowerCase()
      );
      return item.id;
    } catch (e) {
      return null;
    }
  }

  /// Dynamic engine that merges global defaults with user history, sorted by usage frequency
  List<SmartItem> _getMergedDictionary() {
    final Map<String, SmartItem> merged = {};
    final Map<String, int> frequency = {};

    // 1. Load Global Baseline
    for (var item in MockDictionary.globalItems) {
      final key = item.title.toLowerCase();
      merged[key] = item;
      frequency[key] = 0; // Baseline frequency
    }

    // 2. Overlay User's Historical Data
    // Loops chronologically so the most recent edits overwrite older data.
    for (var item in _items) {
      final key = item.title.toLowerCase();
      merged[key] = SmartItem(
        title: item.title, // Preserve user's preferred casing
        category: item.category,
        store: item.type,
        unit: item.unit,
        tags: item.attributeRows,
      );
      // Increment frequency counter for every historical occurrence
      frequency[key] = (frequency[key] ?? 0) + 1;
    }

    // 3. Sort by Frequency (Most popular first)
    final sortedItems = merged.values.toList();
    sortedItems.sort((a, b) {
      final freqA = frequency[a.title.toLowerCase()] ?? 0;
      final freqB = frequency[b.title.toLowerCase()] ?? 0;
      return freqB.compareTo(freqA);
    });

    return sortedItems;
  }

  /// Searches the frequency-sorted dictionary
  List<SmartItem> searchSmartDictionary(String query) {
    final allItems = _getMergedDictionary();

    if (query.trim().isEmpty) {
      // Return top 5 most popular items, explicitly hiding anything currently active
      return allItems
          .where((item) => !isActiveItem(item.title))
          .take(5)
          .toList();
    }

    final q = query.toLowerCase().trim();
    return allItems
        .where((item) => item.title.toLowerCase().contains(q))
        .toList();
  }

  /// Finds an exact match in the merged dictionary for quick-save application
  SmartItem? getExactDictionaryMatch(String title) {
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
        _items[i] = _items[i].copyWith(isCompleted: true);
        changed = true;
      }
    }
    if (changed) {
      _buildDisplayList();
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
      _saveItemsToStorage();
      notifyListeners();
    }
  }

  List<String> checkSelectedItems() {
    final checkedIds = List<String>.from(_selectedItemIds);
    for (String id in checkedIds) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) _items[index] = _items[index].copyWith(isCompleted: true);
    }
    clearSelection();
    _buildDisplayList();
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
    _saveItemsToStorage();
    return deletedIds;
  }

  // --- UNDO ENGINE ---
  void restoreItems(List<String> ids) {
    bool changed = false;
    for (String id in ids) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(isDeleted: false, isCompleted: false);
        changed = true;
      }
    }
    if (changed) {
      _buildDisplayList();
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
      _saveItemsToStorage();
    }
  }

  // --- MULTI-DIMENSIONAL EDIT ITEM (SECTION AWARE) ---
  void editItem(String id, String newTitle, List<String> newAttributes, String type, String category, int newQty, String newUnit) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final oldItem = _items[index];

      // --- NEW: MERGE CONFLICT RESOLUTION ---
      // Check if correcting a typo causes a collision with an existing active item
      final existingId = getActiveItemIdByTitle(newTitle);
      if (existingId != null && existingId != id) {
        final existingIndex = _items.indexWhere((item) => item.id == existingId);
        final existingItem = _items[existingIndex];

        // 1. Merge into the existing item (add quantities, adopt newest settings)
        _items[existingIndex] = existingItem.copyWith(
          quantity: (existingItem.quantity + newQty).clamp(0, 99),
          attributeRows: newAttributes,
          type: type.trim().isEmpty ? "Any" : type.trim(),
          category: category.trim().isEmpty ? "Everything Else" : category.trim(),
          unit: newUnit,
        );

        // 2. Permanently delete the typo item to complete the merge
        _items.removeAt(index);

        _recalculateWraps();
        _buildDisplayList();
        _saveItemsToStorage();
        triggerSequentialFlash(existingId); // Flash the newly merged item
        notifyListeners();
        return;
      }

      // --- NORMAL EDIT ROUTINE ---
      final safeType = type.trim().isEmpty ? "Any" : type.trim();
      final safeCategory = category.trim().isEmpty ? "Everything Else" : category.trim();

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
      );

      _recalculateWraps();
      _buildDisplayList();
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
      notifyListeners();
    }
  }

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
      _items[index] = _items[index].copyWith(isCompleted: !_items[index].isCompleted);
      _buildDisplayList();
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
      _saveItemsToStorage();
      notifyListeners();
    }
    return id;
  }
}