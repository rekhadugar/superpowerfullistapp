import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_models.dart';

class SettingsProvider extends ChangeNotifier {
  List<StoreConfig> _stores = [];
  List<CategoryConfig> _categories = [];

  // FIXED 1: Separate anchors for Stores and Categories
  bool _anchorStoreToTop = false;
  bool _anchorCategoryToTop = false;

  bool get anchorStoreToTop => _anchorStoreToTop;
  bool get anchorCategoryToTop => _anchorCategoryToTop;
  List<StoreConfig> get stores => _stores;
  List<CategoryConfig> get categories => _categories;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _anchorStoreToTop = prefs.getBool('anchorStoreToTop') ?? false;
    _anchorCategoryToTop = prefs.getBool('anchorCategoryToTop') ?? false;

    final storesJson = prefs.getString('global_stores');
    if (storesJson != null) {
      final List<dynamic> decoded = jsonDecode(storesJson);
      _stores = decoded.map((map) => StoreConfig.fromMap(map)).toList();
    } else {
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
      _categories = [
        CategoryConfig(id: 'c1', name: 'Produce'),
        CategoryConfig(id: 'c2', name: 'Dairy'),
        CategoryConfig(id: 'c3', name: 'Bakery'),
        CategoryConfig(id: 'default_category', name: 'Everything Else', isLocked: true),
      ];
    }

    _enforceStoreAnchor();
    _enforceCategoryAnchor();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('anchorStoreToTop', _anchorStoreToTop);
    await prefs.setBool('anchorCategoryToTop', _anchorCategoryToTop);
    await prefs.setString('global_stores', jsonEncode(_stores.map((s) => s.toMap()).toList()));
    await prefs.setString('global_categories', jsonEncode(_categories.map((c) => c.toMap()).toList()));
  }

  // --- NEW: SEEDING ENGINE (Fixes Bugs 3, 4, & 5) ---
  void seedFromExisting(List<String> existingStores, List<String> existingCategories) {
    bool changed = false;

    for (String s in existingStores) {
      if (s.toLowerCase() == 'any') continue; // Locked default handles this
      if (!_stores.any((config) => config.name.toLowerCase() == s.toLowerCase())) {
        _stores.add(StoreConfig(id: DateTime.now().microsecondsSinceEpoch.toString() + s.hashCode.toString(), name: s));
        changed = true;
      }
    }

    for (String c in existingCategories) {
      if (c.toLowerCase() == 'everything else') continue; // Locked default handles this
      if (!_categories.any((config) => config.name.toLowerCase() == c.toLowerCase())) {
        _categories.add(CategoryConfig(id: DateTime.now().microsecondsSinceEpoch.toString() + c.hashCode.toString(), name: c));
        changed = true;
      }
    }

    if (changed) {
      _enforceStoreAnchor();
      _enforceCategoryAnchor();
      _saveSettings();
      notifyListeners();
    }
  }

  void toggleStoreAnchor() {
    _anchorStoreToTop = !_anchorStoreToTop;
    _enforceStoreAnchor();
    _saveSettings();
    notifyListeners();
  }

  void toggleCategoryAnchor() {
    _anchorCategoryToTop = !_anchorCategoryToTop;
    _enforceCategoryAnchor();
    _saveSettings();
    notifyListeners();
  }

  void _enforceStoreAnchor() {
    final lockedIndex = _stores.indexWhere((s) => s.isLocked);
    if (lockedIndex != -1) {
      final locked = _stores.removeAt(lockedIndex);
      _anchorStoreToTop ? _stores.insert(0, locked) : _stores.add(locked);
    }
  }

  void _enforceCategoryAnchor() {
    final lockedIndex = _categories.indexWhere((c) => c.isLocked);
    if (lockedIndex != -1) {
      final locked = _categories.removeAt(lockedIndex);
      _anchorCategoryToTop ? _categories.insert(0, locked) : _categories.add(locked);
    }
  }

  // --- STORE MANAGEMENT ---
  void addStore(String name, String address) {
    _stores.add(StoreConfig(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name.trim(), address: address.trim()));
    _enforceStoreAnchor();
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
    _enforceStoreAnchor();
    _saveSettings();
    notifyListeners();
  }

  // --- CATEGORY MANAGEMENT ---
  void addCategory(String name) {
    _categories.add(CategoryConfig(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name.trim()));
    _enforceCategoryAnchor();
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
    _enforceCategoryAnchor();
    _saveSettings();
    notifyListeners();
  }
}