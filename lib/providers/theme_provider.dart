import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontSize { small, medium, large }

class ThemeProvider extends ChangeNotifier {
  double _textScaleMultiplier = 1.0;
  bool _isInitialized = false;

  double get textScaleMultiplier => _textScaleMultiplier;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // FIXED: Enforce the strict 0.5 to 1.5 clamp immediately on load
    // to sanitize any legacy data from SharedPreferences.
    _textScaleMultiplier = (prefs.getDouble('fluid_text_scale') ?? 1.0).clamp(0.5, 1.5);

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setFluidScale(double scale) async {
    if (_textScaleMultiplier != scale) {
      // FIXED: Clamped to 1.5 max as requested
      _textScaleMultiplier = scale.clamp(0.5, 1.5);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fluid_text_scale', _textScaleMultiplier);
      notifyListeners();
    }
  }
}