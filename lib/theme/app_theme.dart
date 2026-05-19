import 'package:flutter/material.dart';

class AppTheme {
  // 1. Core Color Tokens from React Native Spec
  static const Color background = Color(0xFFF2F2F7); // iOS Grouped Background
  static const Color primary = Color(0xFF007AFF);    // iOS System Blue
  static const Color success = Color(0xFF34C759);    // Shopping Mode Green
  static const Color dragActive = Color(0xFFE5E9F0); // Darker grey/blue for active drag
  static const Color textSecondary = Color(0xFF8E8E93); // Counts/Hints
  static const Color surface = Color(0xFFFFFFFF);    // Pure White
  static const Color border = Color(0xFFE5E5EA);     // Standard iOS border
  static const Color error = Colors.red;


  // 2. Global Theme Configuration
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      iconTheme: IconThemeData(color: primary),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: surface,
      elevation: 8,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      surface: surface,
      // 'background' has been removed to resolve the Material 3 deprecation warning
    ),
  );
}