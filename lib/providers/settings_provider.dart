import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_models.dart';
import '../models/app_list_type.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // --- DYNAMIC TAXONOMY STATE ---
  List<AppListType> _customTypes = [];

  // Data Maps keyed by AppListType.id
  Map<String, List<GroupConfig>> _axis1Groups = {};
  Map<String, List<GroupConfig>> _axis2Groups = {};

  Map<String, bool> _anchorAxis1ToTop = {};
  Map<String, bool> _anchorAxis2ToTop = {};

  List<AppListType> get allTypes => [...AppListType.systemDefaults, ..._customTypes];

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Custom Types
    final customTypesJson = prefs.getString('custom_list_types');
    if (customTypesJson != null) {
      final List<dynamic> decoded = jsonDecode(customTypesJson);
      _customTypes = decoded.map((m) => AppListType.fromMap(m)).toList();
    }

    // 2. Load Maps (Now passes through the Auto-Sanitizer)
    _axis1Groups = _loadGroupMap(prefs, 'map_axis1_groups');
    _axis2Groups = _loadGroupMap(prefs, 'map_axis2_groups');

    // 3. Load Anchors
    _anchorAxis1ToTop = _loadAnchorMap(prefs, 'map_anchor_axis1');
    _anchorAxis2ToTop = _loadAnchorMap(prefs, 'map_anchor_axis2');

    // 4. Factory Initialization
    _ensureSystemDefaultsExist();

    for (var type in allTypes) {
      _enforceAnchorLogic(type.id, isAxis1: true);
      _enforceAnchorLogic(type.id, isAxis1: false);
    }

    _isInitialized = true;
    notifyListeners();
  }

  // FIXED: Added an Auto-Sanitizer to repair corrupted duplicate IDs from previous crashes
  Map<String, List<GroupConfig>> _loadGroupMap(SharedPreferences prefs, String key) {
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);

    return decoded.map((k, v) {
      final list = (v as List).map((item) => GroupConfig.fromMap(item)).toList();

      // SANITIZER: Detects and fixes duplicate IDs on load
      final Set<String> seenIds = {};
      for (int i = 0; i < list.length; i++) {
        if (seenIds.contains(list[i].id)) {
          // If duplicate found, append a safe unique string
          list[i] = list[i].copyWith(id: '${list[i].id}_repaired_$i');
        }
        seenIds.add(list[i].id);
      }

      return MapEntry(k, list);
    });
  }

  Map<String, bool> _loadAnchorMap(SharedPreferences prefs, String key) {
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((k, v) => MapEntry(k, v as bool));
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_list_types', jsonEncode(_customTypes.map((t) => t.toMap()).toList()));

    final axis1Enc = _axis1Groups.map((k, v) => MapEntry(k, v.map((g) => g.toMap()).toList()));
    final axis2Enc = _axis2Groups.map((k, v) => MapEntry(k, v.map((g) => g.toMap()).toList()));

    await prefs.setString('map_axis1_groups', jsonEncode(axis1Enc));
    await prefs.setString('map_axis2_groups', jsonEncode(axis2Enc));
    await prefs.setString('map_anchor_axis1', jsonEncode(_anchorAxis1ToTop));
    await prefs.setString('map_anchor_axis2', jsonEncode(_anchorAxis2ToTop));
  }

  void _ensureSystemDefaultsExist() {
    if (!_axis1Groups.containsKey(AppListType.shopping.id)) {
      _axis1Groups[AppListType.shopping.id] = [
        GroupConfig(id: 'default_s1', name: 'Any', isLocked: true),
        GroupConfig(id: 's1', name: 'Costco'),
        GroupConfig(id: 's2', name: 'Target'),
        GroupConfig(id: 's3', name: 'Walmart'),
      ];
    }
    if (!_axis2Groups.containsKey(AppListType.shopping.id)) {
      _axis2Groups[AppListType.shopping.id] = [
        GroupConfig(id: 'c1', name: 'Produce'),
        GroupConfig(id: 'c2', name: 'Dairy'),
        GroupConfig(id: 'default_c1', name: 'Everything Else', isLocked: true),
      ];
    }

    for (var type in AppListType.systemDefaults) {
      if (!_axis1Groups.containsKey(type.id)) {
        _axis1Groups[type.id] = [GroupConfig(id: '${type.id}_a1_def', name: 'Any', isLocked: true)];
      }
      if (!_axis2Groups.containsKey(type.id)) {
        _axis2Groups[type.id] = [GroupConfig(id: '${type.id}_a2_def', name: 'Everything Else', isLocked: true)];
      }
    }
  }

  // --- PUBLIC GETTERS ---
  List<GroupConfig> getAxis1Groups(String typeId) => _axis1Groups[typeId] ?? [];
  List<GroupConfig> getAxis2Groups(String typeId) => _axis2Groups[typeId] ?? [];

  bool getAnchorAxis1(String typeId) => _anchorAxis1ToTop[typeId] ?? false;
  bool getAnchorAxis2(String typeId) => _anchorAxis2ToTop[typeId] ?? false;

  AppListType getTypeById(String typeId) {
    return allTypes.firstWhere((t) => t.id == typeId, orElse: () => AppListType.shopping);
  }

  // --- CUSTOM TYPE MANAGEMENT ---
  void createCustomType(String name, String axis1Label, String axis2Label) {
    final newType = AppListType(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      axis1Label: axis1Label.trim(),
      axis2Label: axis2Label.trim(),
      iconCodePoint: Icons.folder_special_outlined.codePoint,
    );
    _customTypes.add(newType);

    _axis1Groups[newType.id] = [GroupConfig(id: '${newType.id}_a1_def', name: 'Any', isLocked: true)];
    _axis2Groups[newType.id] = [GroupConfig(id: '${newType.id}_a2_def', name: 'Everything Else', isLocked: true)];

    _saveSettings();
    notifyListeners();
  }

  // --- GROUP OPERATIONS ---
  void toggleAnchor(String typeId, {required bool isAxis1}) {
    if (isAxis1) {
      _anchorAxis1ToTop[typeId] = !(_anchorAxis1ToTop[typeId] ?? false);
    } else {
      _anchorAxis2ToTop[typeId] = !(_anchorAxis2ToTop[typeId] ?? false);
    }
    _enforceAnchorLogic(typeId, isAxis1: isAxis1);
    _saveSettings();
    notifyListeners();
  }

  void _enforceAnchorLogic(String typeId, {required bool isAxis1}) {
    final groups = isAxis1 ? _axis1Groups[typeId] : _axis2Groups[typeId];
    if (groups == null) return;

    final anchorToTop = isAxis1 ? getAnchorAxis1(typeId) : getAnchorAxis2(typeId);
    final lockedIndex = groups.indexWhere((g) => g.isLocked);

    if (lockedIndex != -1) {
      final locked = groups.removeAt(lockedIndex);
      anchorToTop ? groups.insert(0, locked) : groups.add(locked);
    }
  }

  void addGroup(String typeId, String name, String subtitle, {required bool isAxis1}) {
    final groups = isAxis1 ? _axis1Groups[typeId] : _axis2Groups[typeId];
    if (groups != null) {
      // FIXED: Uses Microseconds + Hashcode to guarantee unique IDs during fast loop seeding
      final safeId = '${DateTime.now().microsecondsSinceEpoch}_${name.hashCode}';

      groups.add(GroupConfig(
        id: safeId,
        name: name.trim(),
        subtitle: subtitle.trim(),
      ));
      _enforceAnchorLogic(typeId, isAxis1: isAxis1);
      _saveSettings();
      notifyListeners();
    }
  }

  void updateGroup(String typeId, String groupId, String newName, String newSubtitle, {required bool isAxis1}) {
    final groups = isAxis1 ? _axis1Groups[typeId] : _axis2Groups[typeId];
    if (groups != null) {
      final index = groups.indexWhere((g) => g.id == groupId);
      if (index != -1 && !groups[index].isLocked) {
        groups[index] = groups[index].copyWith(name: newName.trim(), subtitle: newSubtitle.trim());
        _saveSettings();
        notifyListeners();
      }
    }
  }

  void deleteGroup(String typeId, String groupId, {required bool isAxis1}) {
    final groups = isAxis1 ? _axis1Groups[typeId] : _axis2Groups[typeId];
    if (groups != null) {
      groups.removeWhere((g) => g.id == groupId && !g.isLocked);
      _saveSettings();
      notifyListeners();
    }
  }

  void reorderGroups(String typeId, int oldIndex, int newIndex, {required bool isAxis1}) {
    final groups = isAxis1 ? _axis1Groups[typeId] : _axis2Groups[typeId];
    if (groups == null) return;

    if (oldIndex < newIndex) newIndex -= 1;
    if (groups[oldIndex].isLocked) return;

    final item = groups.removeAt(oldIndex);
    groups.insert(newIndex, item);
    _enforceAnchorLogic(typeId, isAxis1: isAxis1);
    _saveSettings();
    notifyListeners();
  }

  // --- CASCADING DELETE PROTOCOL ---
  void deleteCustomType(String typeId) {
    // 1. Failsafe: Prevent deletion of core system types
    if (AppListType.systemDefaults.any((sys) => sys.id == typeId)) return;

    // 2. Remove the Type
    _customTypes.removeWhere((t) => t.id == typeId);

    // 3. Wipe the associated group dictionaries and anchors
    _axis1Groups.remove(typeId);
    _axis2Groups.remove(typeId);
    _anchorAxis1ToTop.remove(typeId);
    _anchorAxis2ToTop.remove(typeId);

    _saveSettings();
    notifyListeners();
  }
}