import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/macro_list.dart';
import '../models/list_type.dart';

class MacroListProvider extends ChangeNotifier {
  List<MacroList> _lists = [];
  String? _activeListId;
  bool _isInitialized = false;

  List<MacroList> get lists => _lists;
  String? get activeListId => _activeListId;
  MacroList? get activeList => _lists.where((l) => l.id == _activeListId).firstOrNull;
  bool get isInitialized => _isInitialized;

  MacroListProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('macro_lists');
    final String? savedActiveId = prefs.getString('active_list_id');

    if (listsJson != null) {
      final List<dynamic> decoded = jsonDecode(listsJson);
      _lists = decoded.map((map) => MacroList.fromMap(map)).toList();
    }

    if (_lists.isNotEmpty) {
      if (savedActiveId != null && _lists.any((l) => l.id == savedActiveId)) {
        _activeListId = savedActiveId;
      } else {
        _activeListId = _lists.first.id;
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_lists.map((l) => l.toMap()).toList());
    await prefs.setString('macro_lists', encoded);
    if (_activeListId != null) {
      await prefs.setString('active_list_id', _activeListId!);
    }
  }

  Future<void> setActiveList(String id) async {
    if (_activeListId != id) {
      _activeListId = id;
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> createNewList(String name, ListType type) async {
    final newList = MacroList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Untitled List' : name.trim(),
      type: type,
      createdAt: DateTime.now(),
    );

    _lists.add(newList);
    _activeListId = newList.id;
    await _saveToStorage();
    notifyListeners();
  }
}