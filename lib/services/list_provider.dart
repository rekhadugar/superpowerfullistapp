import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/list_item.dart';

class ListProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ListItem> _items = [];
  List<ListItem> get items => _items;

  String _activeType = 'All Items';
  String get activeType => _activeType;

  void setActiveType(String type) {
    _activeType = type;
    notifyListeners();
  }

  // NEW: Smart Search State
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void toggleSearch() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      _searchQuery = ''; // Clear the query when closing search
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool _isGlobalCompactMode = false;
  bool get isGlobalCompactMode => _isGlobalCompactMode;

  void toggleGlobalCompactMode() {
    _isGlobalCompactMode = !_isGlobalCompactMode;
    _expandedItemId = null;
    notifyListeners();
  }

  String? _expandedItemId;
  String? get expandedItemId => _expandedItemId;

  void toggleExpandedItem(String id) {
    if (_expandedItemId == id) {
      _expandedItemId = null;
    } else {
      _expandedItemId = id;
    }
    notifyListeners();
  }

  void clearExpandedItem() {
    if (_expandedItemId != null) {
      _expandedItemId = null;
      notifyListeners();
    }
  }

  String _groupBy = 'Category';
  String get groupBy => _groupBy;

  void setGroupBy(String method) {
    _groupBy = method;
    _expandedItemId = null;
    notifyListeners();
  }

  ListProvider() {
    _listenToItems();
  }

  List<String> get availableLists {
    final Set<String> types = {'All Items'};
    for (var item in _items) {
      if (!item.isDeleted) {
        types.add(item.type);
      }
    }
    final sortedTypes = types.toList();
    sortedTypes.sort((a, b) {
      if (a == 'All Items') return -1;
      if (b == 'All Items') return 1;
      return a.compareTo(b);
    });
    return sortedTypes;
  }

  List<String> _getSortedGroupNames(Iterable<String> unsortedGroups) {
    final groups = unsortedGroups.toList();
    groups.sort();
    return groups;
  }

  void _sortItemsWithinGroup(List<ListItem> items) {
    items.sort((a, b) => a.order.compareTo(b.order));
  }

  List<dynamic> get groupedAndSortedItems {
    final activeItems = _items.where((i) {
      if (i.isCompleted || i.isDeleted) return false;
      if (_activeType != 'All Items' && i.type != _activeType) return false;

      // NEW: Smart Search Filtering Logic
      if (_isSearching && _searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();

        final matchesName = i.name.toLowerCase().contains(query);
        final matchesCategory = i.category.toLowerCase().contains(query);
        final matchesContext = i.context.toLowerCase().contains(query);
        final matchesLocation = i.locations.any((loc) => loc.toLowerCase().contains(query));

        if (!matchesName && !matchesCategory && !matchesContext && !matchesLocation) {
          return false;
        }
      }

      return true;
    }).toList();

    if (_groupBy == 'None') {
      _sortItemsWithinGroup(activeItems);
      return activeItems;
    }

    final Map<String, List<ListItem>> groups = {};

    if (_groupBy == 'Category') {
      for (var item in activeItems) {
        groups.putIfAbsent(item.category, () => []).add(item);
      }
    } else if (_groupBy == 'Store') {
      for (var item in activeItems) {
        if (item.locations.isEmpty || (item.locations.length == 1 && item.locations.first == 'Anywhere')) {
          groups.putIfAbsent('Anywhere', () => []).add(item);
        } else {
          for (var loc in item.locations) {
            if (loc != 'Anywhere') {
              groups.putIfAbsent(loc, () => []).add(item);
            }
          }
        }
      }
    } else if (_groupBy == 'List') {
      for (var item in activeItems) {
        groups.putIfAbsent(item.type, () => []).add(item);
      }
    }

    final List<dynamic> flattenedList = [];
    final sortedGroupNames = _getSortedGroupNames(groups.keys);

    for (var groupName in sortedGroupNames) {
      flattenedList.add(groupName.toUpperCase());
      final itemsInGroup = groups[groupName]!;
      _sortItemsWithinGroup(itemsInGroup);
      flattenedList.addAll(itemsInGroup);
    }

    return flattenedList;
  }

  void _listenToItems() {
    _db.collection('items').orderBy('order').snapshots().listen((snapshot) {
      _items = snapshot.docs
          .map((doc) => ListItem.fromMap(doc.data(), doc.id))
          .where((item) => !item.isDeleted)
          .toList();
      notifyListeners();
    });
  }

  Future<void> addItem({
    required String name,
    required String type,
    required String category,
    required List<String> locations,
    required String context,
    int quantity = 1,
    String unit = 'pcs',
  }) async {
    final now = Timestamp.now();
    final currentUser = 'Dhiraj';

    final newItem = ListItem(
      id: '',
      name: name,
      type: type,
      category: category,
      locations: locations,
      unit: unit,
      context: context,
      order: _items.length,
      createdBy: currentUser,
      createdAt: now,
      updatedBy: currentUser,
      updatedAt: now,
    );
    await _db.collection('items').add(newItem.toMap());
  }

  Future<void> toggleItemStatus(String id, bool currentStatus) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isCompleted = !currentStatus;
      notifyListeners();
    }

    await _db.collection('items').doc(id).update({
      'isCompleted': !currentStatus,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final flatList = List<dynamic>.from(groupedAndSortedItems);
    if (oldIndex >= flatList.length || newIndex >= flatList.length) return;

    final draggedElement = flatList[oldIndex];
    if (draggedElement is String) return;

    final draggedItem = draggedElement as ListItem;

    flatList.removeAt(oldIndex);
    flatList.insert(newIndex, draggedItem);

    WriteBatch batch = _db.batch();
    String currentGroupName = 'Uncategorized';
    int currentOrderIndex = 0;

    for (var element in flatList) {
      if (element is String) {
        currentGroupName = element;
      } else if (element is ListItem) {
        final item = element;
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        if (item.order != currentOrderIndex) {
          item.order = currentOrderIndex;
          updates['order'] = currentOrderIndex;
          needsUpdate = true;
        }

        if (item.id == draggedItem.id && _groupBy != 'None') {
          String formattedGroup = currentGroupName.split(' ').map((word) =>
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : ''
          ).join(' ');

          if (_groupBy == 'Store' && !item.locations.contains(formattedGroup)) {
            item.locations = [formattedGroup];
            updates['locations'] = item.locations;
            needsUpdate = true;
          } else if (_groupBy == 'Category' && item.category != formattedGroup) {
            item.category = formattedGroup;
            updates['category'] = item.category;
            needsUpdate = true;
          } else if (_groupBy == 'List' && item.type != formattedGroup) {
            item.type = formattedGroup;
            updates['type'] = item.type;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          batch.update(_db.collection('items').doc(item.id), updates);
        }

        currentOrderIndex++;
      }
    }

    notifyListeners();
    await batch.commit();
  }

  Future<void> deleteItem(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isDeleted = true;
      notifyListeners();
    }

    await _db.collection('items').doc(id).update({
      'isDeleted': true,
      'deletedBy': 'Dhiraj',
      'deletedAt': Timestamp.now(),
    });
  }

  Future<void> restoreItem(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isDeleted = false;
      notifyListeners();
    }

    await _db.collection('items').doc(id).update({
      'isDeleted': false,
      'deletedBy': FieldValue.delete(),
      'deletedAt': FieldValue.delete(),
    });
  }

  Future<void> updateQuantity(String id, int newQuantity) async {
    if (newQuantity < 1) return;

    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }

    await _db.collection('items').doc(id).update({
      'quantity': newQuantity,
    });
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required String type,
    required String category,
    required List<String> locations,
    required String contextString,
    required int quantity,
    required String unit,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final oldItem = _items[index];
      _items[index] = ListItem(
        id: oldItem.id,
        name: name,
        type: type,
        category: category,
        locations: locations,
        context: contextString,
        quantity: quantity,
        unit: unit,
        order: oldItem.order,
        isCompleted: oldItem.isCompleted,
        isDeleted: oldItem.isDeleted,
        createdBy: oldItem.createdBy,
        createdAt: oldItem.createdAt,
        updatedBy: oldItem.updatedBy,
        updatedAt: oldItem.updatedAt,
      );
      notifyListeners();
    }

    try {
      await _db.collection('items').doc(id).update({
        'name': name,
        'type': type,
        'category': category,
        'locations': locations,
        'context': contextString,
        'quantity': quantity,
        'unit': unit,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating item $id: $e');
    }
  }
}