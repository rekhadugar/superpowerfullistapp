import 'package:flutter/material.dart';
import '../models/macro_list.dart';
import '../models/list_type.dart';

class MacroListProvider extends ChangeNotifier {
  List<MacroList> _lists = [];
  String? _activeListId;

  List<MacroList> get lists => _lists;
  String? get activeListId => _activeListId;
  MacroList? get activeList => _lists.where((l) => l.id == _activeListId).firstOrNull;

  MacroListProvider() {
    _initializeDefaultState();
  }

  void _initializeDefaultState() {
    // Default Launch State requirement
    final defaultList = MacroList(
      id: 'default_shopping_1',
      name: 'New List',
      type: ListType.shopping,
      createdAt: DateTime.now(),
    );

    _lists.add(defaultList);
    _activeListId = defaultList.id;
    notifyListeners();
  }

  void setActiveList(String id) {
    if (_activeListId != id) {
      _activeListId = id;
      notifyListeners();
    }
  }

  void createNewList(String name, ListType type) {
    final newList = MacroList(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Mock ID
      name: name.trim().isEmpty ? 'Untitled List' : name.trim(),
      type: type,
      createdAt: DateTime.now(),
    );

    _lists.add(newList);
    _activeListId = newList.id; // Automatically switch to the new list
    notifyListeners();
  }
}