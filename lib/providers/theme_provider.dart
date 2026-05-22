import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontSize { small, medium, large }

class ThemeProvider extends ChangeNotifier {
  AppFontSize _fontSize = AppFontSize.medium;
  bool _isInitialized = false;

  AppFontSize get fontSize => _fontSize;
  bool get isInitialized => _isInitialized;

  // The math multipliers that will feed into the engine
  double get textScaleMultiplier {
    switch (_fontSize) {
      case AppFontSize.small: return 0.85;
      case AppFontSize.medium: return 1.0;
      case AppFontSize.large: return 1.35;
    }
  }

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSize = prefs.getString('font_size');

    if (savedSize != null) {
      _fontSize = AppFontSize.values.firstWhere(
            (e) => e.name == savedSize,
        orElse: () => AppFontSize.medium,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setFontSize(AppFontSize size) async {
    if (_fontSize != size) {
      _fontSize = size;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('font_size', size.name);
      notifyListeners(); // This triggers the MaterialApp to rebuild the MediaQuery
    }
  }
}