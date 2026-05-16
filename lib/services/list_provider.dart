import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/list_item.dart';

class ListProvider extends ChangeNotifier {
  // Connect directly to your Listicle Firestore database
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ListItem> _items = [];
  List<ListItem> get items => _items;

  // When the provider boots up, start listening to the cloud immediately
  ListProvider() {
    _listenToItems();
  }

  // THE MAGIC: A real-time stream that watches the 'items' collection
  void _listenToItems() {
    _db.collection('items')
        .orderBy('order') // Keeps your drag-and-drop sorting
        .snapshots()
        .listen((snapshot) {

      // Convert the raw cloud data into our clean Dart objects
      _items = snapshot.docs
          .map((doc) => ListItem.fromMap(doc.data(), doc.id))
          .toList();

      // Tell the screen to redraw with the live data
      notifyListeners();
    });
  }

  // --- ACTIONS ---

  // 1. Add a new item to the cloud
  Future<void> addItem(String name, String category) async {
    final newItem = ListItem(
      id: '', // Firestore generates this automatically
      name: name,
      category: category, // Now saving the selected category
      order: _items.length,
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
    // Remove locally first for an instant UI response
    _items.removeWhere((item) => item.id == id);
    notifyListeners();

    // Then delete from Firestore
    await _db.collection('items').doc(id).delete();
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
}
