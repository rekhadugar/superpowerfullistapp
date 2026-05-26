import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/macro_list.dart';

class MacroListProvider extends ChangeNotifier {
  List<MacroList> _lists = [];
  String? _activeListId;
  bool _isInitialized = false;

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

  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    final listsJson = prefs.getString('macro_lists');

    if (listsJson != null) {
      final List<dynamic> decoded = jsonDecode(listsJson);
      _lists = decoded.map((m) => MacroList.fromMap(m)).toList();
    } else {
      _lists = [
        MacroList(
          id: 'default_list_1',
          name: 'Groceries',
          typeId: 'sys_shopping',
          displayOrder: 100.0,
          createdAt: DateTime.now(), // FIXED: Added missing parameter
        )
      ];
    }

    _lists.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    _activeListId = prefs.getString('active_list_id');
    if (_activeListId == null && _lists.isNotEmpty) {
      _activeListId = _lists.first.id;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_lists.map((l) => l.toMap()).toList());
    await prefs.setString('macro_lists', encoded);
  }

  void setActiveList(String id) async {
    _activeListId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_list_id', id);
  }

  void addList(String name, String typeId) {
    double maxOrder = 0.0;
    for (var list in _lists) {
      if (list.displayOrder > maxOrder) maxOrder = list.displayOrder;
    }

    final newList = MacroList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      typeId: typeId,
      displayOrder: maxOrder + 100.0,
      createdAt: DateTime.now(), // FIXED: Added missing parameter
    );

    _lists.add(newList);
    _saveLists();
    notifyListeners();
  }

  void updateList(String id, String newName) {
    final index = _lists.indexWhere((l) => l.id == id);
    if (index != -1) {
      _lists[index] = _lists[index].copyWith(name: newName.trim());
      _saveLists();
      notifyListeners();
    }
  }

  void deleteList(String id) {
    _lists.removeWhere((l) => l.id == id);
    if (_activeListId == id) {
      _activeListId = _lists.isNotEmpty ? _lists.first.id : null;
    }
    _saveLists();
    notifyListeners();
  }

  void reorderLists(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _lists.removeAt(oldIndex);
    _lists.insert(newIndex, item);

    for (int i = 0; i < _lists.length; i++) {
      _lists[i] = _lists[i].copyWith(displayOrder: (i + 1) * 100.0);
    }

    _saveLists();
    notifyListeners();
  }

  // --- CASCADING DELETE PROTOCOL ---
  Future<void> deleteAllListsOfType(String typeId) async {
    final listsToDelete = _lists.where((l) => l.typeId == typeId).toList();
    if (listsToDelete.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Dig into local storage and wipe all orphaned item data to save space
    for (var list in listsToDelete) {
      await prefs.remove('items_${list.id}');
      await prefs.remove('last_purge_date_${list.id}');
    }

    // 2. Remove the lists from memory
    _lists.removeWhere((l) => l.typeId == typeId);

    // 3. Fallback routing if the user was currently looking at one of the deleted lists
    if (listsToDelete.any((l) => l.id == _activeListId)) {
      _activeListId = _lists.isNotEmpty ? _lists.first.id : null;
      if (_activeListId != null) {
        await prefs.setString('active_list_id', _activeListId!);
      } else {
        await prefs.remove('active_list_id');
      }
    }

    _saveLists();
    notifyListeners();
  }
}