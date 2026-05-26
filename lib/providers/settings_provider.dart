import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_models.dart';

class SettingsProvider extends ChangeNotifier {
  List<StoreConfig> _stores = [];
  List<CategoryConfig> _categories = [];
  bool _anchorDefaultsToTop = false;

  bool get anchorDefaultsToTop => _anchorDefaultsToTop;
  List<StoreConfig> get stores => _stores;
  List<CategoryConfig> get categories => _categories;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _anchorDefaultsToTop = prefs.getBool('anchorDefaultsToTop') ?? false;

    final storesJson = prefs.getString('global_stores');
    if (storesJson != null) {
      final List<dynamic> decoded = jsonDecode(storesJson);
      _stores = decoded.map((map) => StoreConfig.fromMap(map)).toList();
    } else {
      // Default Factory Load
      _stores = [
        StoreConfig(id: 'default_store', name: 'Any', isLocked: true),
        StoreConfig(id: 's1', name: 'Costco'),
        StoreConfig(id: 's2', name: 'Target'),
        StoreConfig(id: 's3', name: 'Walmart'),
        StoreConfig(id: 's4', name: 'Trader Joe\'s'),
      ];
    }

    final categoriesJson = prefs.getString('global_categories');
    if (categoriesJson != null) {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      _categories = decoded.map((map) => CategoryConfig.fromMap(map)).toList();
    } else {
      // Default Factory Load
      _categories = [
        CategoryConfig(id: 'c1', name: 'Produce'),
        CategoryConfig(id: 'c2', name: 'Dairy'),
        CategoryConfig(id: 'c3', name: 'Bakery'),
        CategoryConfig(id: 'default_category', name: 'Everything Else', isLocked: true),
      ];
    }

    _enforceAnchorLogic();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('anchorDefaultsToTop', _anchorDefaultsToTop);
    await prefs.setString('global_stores', jsonEncode(_stores.map((s) => s.toMap()).toList()));
    await prefs.setString('global_categories', jsonEncode(_categories.map((c) => c.toMap()).toList()));
  }

  void toggleAnchor() {
    _anchorDefaultsToTop = !_anchorDefaultsToTop;
    _enforceAnchorLogic();
    _saveSettings();
    notifyListeners();
  }

  void _enforceAnchorLogic() {
    // 1. Force the locked store ('Any') to the exact top or bottom
    final lockedStoreIndex = _stores.indexWhere((s) => s.isLocked);
    if (lockedStoreIndex != -1) {
      final lockedStore = _stores.removeAt(lockedStoreIndex);
      if (_anchorDefaultsToTop) {
        _stores.insert(0, lockedStore);
      } else {
        _stores.add(lockedStore);
      }
    }

    // 2. Force the locked category ('Everything Else') to the exact top or bottom
    final lockedCatIndex = _categories.indexWhere((c) => c.isLocked);
    if (lockedCatIndex != -1) {
      final lockedCat = _categories.removeAt(lockedCatIndex);
      if (_anchorDefaultsToTop) {
        _categories.insert(0, lockedCat);
      } else {
        _categories.add(lockedCat);
      }
    }
  }

  // --- STORE MANAGEMENT ---
  void addStore(String name, String address) {
    _stores.add(StoreConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      address: address.trim(),
    ));
    _enforceAnchorLogic();
    _saveSettings();
    notifyListeners();
  }

  void updateStore(String id, String newName, String newAddress) {
    final index = _stores.indexWhere((s) => s.id == id);
    if (index != -1 && !_stores[index].isLocked) {
      _stores[index] = _stores[index].copyWith(name: newName.trim(), address: newAddress.trim());
      _saveSettings();
      notifyListeners();
    }
  }

  void deleteStore(String id) {
    _stores.removeWhere((s) => s.id == id && !s.isLocked);
    _saveSettings();
    notifyListeners();
  }

  void reorderStores(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    if (_stores[oldIndex].isLocked) return;

    final item = _stores.removeAt(oldIndex);
    _stores.insert(newIndex, item);
    _enforceAnchorLogic();
    _saveSettings();
    notifyListeners();
  }

  // --- CATEGORY MANAGEMENT ---
  void addCategory(String name) {
    _categories.add(CategoryConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
    ));
    _enforceAnchorLogic();
    _saveSettings();
    notifyListeners();
  }

  void updateCategory(String id, String newName) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1 && !_categories[index].isLocked) {
      _categories[index] = _categories[index].copyWith(name: newName.trim());
      _saveSettings();
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id && !c.isLocked);
    _saveSettings();
    notifyListeners();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    if (_categories[oldIndex].isLocked) return;

    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);
    _enforceAnchorLogic();
    _saveSettings();
    notifyListeners();
  }
}