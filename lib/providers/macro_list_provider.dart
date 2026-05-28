import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/macro_list.dart';
import '../services/auth_service.dart';

class MacroListProvider extends ChangeNotifier {
  List<MacroList> _lists = [];
  String? _activeListId;
  bool _isInitialized = false;
  StreamSubscription? _listSubscription;

  List<MacroList> get lists => _lists;
  String? get activeListId => _activeListId;
  bool get isInitialized => _isInitialized;

  MacroList? get activeList {
    try {
      return _lists.firstWhere((l) => l.id == _activeListId);
    } catch (e) {
      return null;
    }
  }

  MacroListProvider() {
    _loadLists();
  }

  @override
  void dispose() {
    _listSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLists() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    _activeListId = prefs.getString('active_list_id');

    final firestore = FirebaseFirestore.instance;
    // The Stream automatically pushes offline/online updates to the UI in real-time
    _listSubscription = firestore
        .collection('users')
        .doc(uid)
        .collection('lists')
        .snapshots()
        .listen((snapshot) {

      _lists = snapshot.docs.map((doc) => MacroList.fromMap(doc.data())).toList();
      _lists.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      if (_lists.isEmpty) {
        addList('Groceries', 'sys_shopping'); // Auto-create default
      } else {
        if (_activeListId == null || !_lists.any((l) => l.id == _activeListId)) {
          _activeListId = _lists.first.id;
          prefs.setString('active_list_id', _activeListId!);
        }
      }

      _isInitialized = true;
      notifyListeners();
    });
  }

  void setActiveList(String id) async {
    _activeListId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_list_id', id);
  }

  Future<void> addList(String name, String typeId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    double maxOrder = 0.0;
    for (var list in _lists) {
      if (list.displayOrder > maxOrder) maxOrder = list.displayOrder;
    }

    final newList = MacroList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      typeId: typeId,
      displayOrder: maxOrder + 100.0,
      createdAt: DateTime.now(),
    );

    // Write to Firestore (will instantly update the stream)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(newList.id)
        .set(newList.toMap());
  }

  Future<void> updateList(String id, String newName) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(id)
        .update({'name': newName.trim()});
  }

  Future<void> deleteList(String id) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    // 1. Delete the list document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(id)
        .delete();

    // 2. Client-side subcollection wipe
    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(id)
        .collection('items')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    if (_activeListId == id) {
      _activeListId = _lists.where((l) => l.id != id).isNotEmpty ? _lists.where((l) => l.id != id).first.id : null;
      final prefs = await SharedPreferences.getInstance();
      if (_activeListId != null) {
        await prefs.setString('active_list_id', _activeListId!);
      } else {
        await prefs.remove('active_list_id');
      }
    }
  }

  Future<void> reorderLists(int oldIndex, int newIndex) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    if (oldIndex < newIndex) newIndex -= 1;
    final item = _lists.removeAt(oldIndex);
    _lists.insert(newIndex, item);

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < _lists.length; i++) {
      final newOrder = (i + 1) * 100.0;
      _lists[i] = _lists[i].copyWith(displayOrder: newOrder);

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('lists')
          .doc(_lists[i].id);
      batch.update(docRef, {'displayOrder': newOrder});
    }
    await batch.commit();
    notifyListeners(); // Optimistic immediate UI update
  }

  Future<void> deleteAllListsOfType(String typeId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final listsToDelete = _lists.where((l) => l.typeId == typeId).toList();
    if (listsToDelete.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (var list in listsToDelete) {
      final listRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('lists')
          .doc(list.id);
      batch.delete(listRef);

      final itemsSnapshot = await listRef.collection('items').get();
      for (var doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();

    if (listsToDelete.any((l) => l.id == _activeListId)) {
      final remaining = _lists.where((l) => l.typeId != typeId).toList();
      _activeListId = remaining.isNotEmpty ? remaining.first.id : null;

      final prefs = await SharedPreferences.getInstance();
      if (_activeListId != null) {
        await prefs.setString('active_list_id', _activeListId!);
      } else {
        await prefs.remove('active_list_id');
      }
    }
  }
}