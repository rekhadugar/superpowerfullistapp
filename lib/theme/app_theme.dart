import 'package:flutter/material.dart';

class AppTheme {
  // 1. Core Color Tokens
  static const Color background = Color(0xFFF2F2F7); // Standard soft gray
  static const Color surface = Colors.white;         // Cards and AppBars
  static const Color textPrimary = Color(0xFF1C1C1E); // Main typography
  static const Color textSecondary = Color(0xFF8E8E93); // Subtitles
  static const Color border = Color(0xFFE5E5EA);     // Card borders
  static const Color primary = Color(0xFF007AFF);    // Interactive blue

  // 2. Global Theme Configuration
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    // This automatically styles EVERY AppBar in the app
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 1,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      surface: surface,
    ),
  );
}