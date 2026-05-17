import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/list_item.dart';

class ListProvider extends ChangeNotifier {
  // Connect directly to your Listicle Firestore database
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ListItem> _items = [];
  // --- ADD THIS TO THE TOP OF YOUR PROVIDER VARIABLES ---
  String _activeType = 'All Items';

  String get activeType => _activeType;

  void setActiveType(String type) {
    _activeType = type;
    notifyListeners();
  }

  bool _groupByStore = false;
  bool get groupByStore => _groupByStore;

  void toggleGroupBy() {
    _groupByStore = !_groupByStore;
    notifyListeners();
  }

  // When the provider boots up, start listening to the cloud immediately
  ListProvider() {

    _listenToItems();
  }



  List<ListItem> get items {
    // We now filter out BOTH deleted AND completed items from the active view
    final activeItems = _items.where((item) => !item.isDeleted && !item.isCompleted).toList();

    if (_activeType == 'All Items') {
      return activeItems;
    }
    return activeItems.where((item) => item.type == _activeType).toList();
  }

  // THE MAGIC: A real-time stream that watches the 'items' collection
  void _listenToItems() {
    _db.collection('items').orderBy('order').snapshots().listen((snapshot) {
      _items = snapshot.docs
          .map((doc) => ListItem.fromMap(doc.data(), doc.id))
      // Client-side filter: only keep items that are NOT soft-deleted
          .where((item) => !item.isDeleted)
          .toList();
      notifyListeners();
    });
  }

  // --- ACTIONS ---

  // 1. Add a new item to the cloud
  Future<void> addItem({
    required String name,
    required String type,
    required String category,
    required List<String> locations,
    required String context,
    int quantity = 1,
    String unit = 'pcs', // ADDED THIS
  }) async {
    final now = Timestamp.now();
    final currentUser = 'Dhiraj'; // Temporary placeholder until we build Authentication

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

  // 2. Toggle completion status in the cloud
  Future<void> toggleItemStatus(String id, bool currentStatus) async {
    await _db.collection('items').doc(id).update({
      'isCompleted': !currentStatus,
    });
  }

  // 3. Save drag-and-drop positions to the cloud
  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Move the item locally first so the UI feels instant
    final ListItem movedItem = _items.removeAt(oldIndex);
    _items.insert(newIndex, movedItem);
    notifyListeners();

    // Create a batch write to update all the new order numbers in Firebase at once
    WriteBatch batch = _db.batch();
    for (int i = 0; i < _items.length; i++) {
      DocumentReference docRef = _db.collection('items').doc(_items[i].id);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }
  // 4. Delete item from the cloud
  Future<void> deleteItem(String id) async {
    // 1. Remove locally first for an instant UI response
    _items.removeWhere((item) => item.id == id);
    notifyListeners();

    // 2. Perform a SOFT DELETE in Firestore
    await _db.collection('items').doc(id).update({
      'isDeleted': true,
      'deletedBy': 'Dhiraj', // Temporary placeholder
      'deletedAt': Timestamp.now(),
    });
  }
  // 5. Update quantity in the cloud
  Future<void> updateQuantity(String id, int newQuantity) async {
    if (newQuantity < 1) return; // Prevent quantity from dropping below 1

    // Update locally for instant UI response
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }

    // Push to Firestore
    await _db.collection('items').doc(id).update({
      'quantity': newQuantity,
    });
  }

  // This handles the magic of changing an item's store/category via drag-and-drop
  Future<void> reorderAndMoveItem(String itemId, String newGroup, List<ListItem> newlyOrderedItems) async {
    // 1. Update the dragged item's group locally
    final draggedItem = newlyOrderedItems.firstWhere((i) => i.id == itemId);
    if (_groupByStore) {
      draggedItem.locations = [newGroup];
    } else {
      draggedItem.category = newGroup;
    }

    // 2. Reassign the 'order' integer for every item based on its new visual position
    for (int i = 0; i < newlyOrderedItems.length; i++) {
      newlyOrderedItems[i].order = i;
    }

    // 3. Update the UI instantly
    _items = newlyOrderedItems;
    notifyListeners();

    // 4. Perform a Firestore Batch Update so we only make 1 network call instead of 50
    final batch = _db.batch();
    for (var item in newlyOrderedItems) {
      final docRef = _db.collection('items').doc(item.id);
      batch.update(docRef, {
        'order': item.order,
        // Only update the group field for the item we actually dragged
        if (item.id == itemId)
          if (_groupByStore) 'locations': [newGroup] else 'category': newGroup,
      });
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
    required String unit, // ADDED THIS
  }) async {
    // 1. Optimistic Local Update (Replacing the whole object to bypass 'final' error)
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
        unit: unit, // ADDED THIS
        order: oldItem.order, // Preserve existing background data
        isCompleted: oldItem.isCompleted,
        isDeleted: oldItem.isDeleted,
      );
      notifyListeners();
    }

    // 2. Firestore Network Update
    try {
      await _db.collection('items').doc(id).update({
        'name': name,
        'type': type,
        'category': category,
        'locations': locations,
        'context': contextString,
        'quantity': quantity,
        'unit': unit, // ADDED THIS
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating item $id: $e');
    }
  }
}
