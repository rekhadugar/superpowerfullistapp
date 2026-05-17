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

  String _groupBy = 'Category';
  String get groupBy => _groupBy;

  void setGroupBy(String method) {
    _groupBy = method;
    notifyListeners();
  }

  ListProvider() {
    _listenToItems();
  }

  List<dynamic> get groupedAndSortedItems {
    final activeItems = _items.where((i) => !i.isCompleted && !i.isDeleted).toList();

    if (_groupBy == 'None') {
      activeItems.sort((a, b) => a.order.compareTo(b.order));
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
    final sortedGroupNames = groups.keys.toList()..sort();

    for (var groupName in sortedGroupNames) {
      flattenedList.add(groupName.toUpperCase());

      final itemsInGroup = groups[groupName]!;
      itemsInGroup.sort((a, b) => a.order.compareTo(b.order));

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

  // CHANGED: Optimistic local update for instant UI feedback
  // CHANGED: Now pushes a fresh updatedAt timestamp so Checked Items can sort by time
  Future<void> toggleItemStatus(String id, bool currentStatus) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isCompleted = !currentStatus;
      notifyListeners();
    }

    await _db.collection('items').doc(id).update({
      'isCompleted': !currentStatus,
      'updatedAt': Timestamp.now(), // THIS IS THE MAGIC LINE
    });
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final ListItem movedItem = _items.removeAt(oldIndex);
    _items.insert(newIndex, movedItem);
    notifyListeners();

    WriteBatch batch = _db.batch();
    for (int i = 0; i < _items.length; i++) {
      DocumentReference docRef = _db.collection('items').doc(_items[i].id);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  // CHANGED: No longer wiped from local memory. Just flagged.
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

  // NEW: Instantly un-flags a deleted item
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

  Future<void> reorderAndMoveItem(String itemId, String newGroup, List<ListItem> newlyOrderedItems) async {
    final draggedItem = newlyOrderedItems.firstWhere((i) => i.id == itemId);

    String formattedGroup = newGroup.split(' ').map((word) =>
    word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : ''
    ).join(' ');

    if (_groupBy == 'Store') {
      draggedItem.locations = [formattedGroup];
    } else if (_groupBy == 'Category') {
      draggedItem.category = formattedGroup;
    } else if (_groupBy == 'List') {
      draggedItem.type = formattedGroup;
    }

    for (int i = 0; i < newlyOrderedItems.length; i++) {
      newlyOrderedItems[i].order = i;
    }

    _items = newlyOrderedItems;
    notifyListeners();

    final batch = _db.batch();
    for (var item in newlyOrderedItems) {
      final docRef = _db.collection('items').doc(item.id);

      Map<String, dynamic> updates = {'order': item.order};

      if (item.id == itemId) {
        if (_groupBy == 'Store') updates['locations'] = [formattedGroup];
        if (_groupBy == 'Category') updates['category'] = formattedGroup;
        if (_groupBy == 'List') updates['type'] = formattedGroup;
      }

      batch.update(docRef, updates);
    }
    await batch.commit();
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