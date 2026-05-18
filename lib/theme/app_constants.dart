import 'package:flutter/cupertino.dart';

class AppConstants {
  // --- Padding & Spacing ---
  static const double padTiny = 6.0;   // NEW: For wrap spacing
  static const double padSmall = 8.0;
  static const double padCompact = 12.0; // NEW: For compact modes/inner padding
  static const double padMedium = 16.0;
  static const double padLarge = 24.0;
  static const double padXLarge = 32.0;

  // --- UI Geometry ---
  static const double stickyHeaderHeight = 56.0;
  static const double endOfListRunway = 160.0;

  static final BorderRadius cardRadius = BorderRadius.circular(12.0);
  static final BorderRadius modalRadius = const BorderRadius.vertical(top: Radius.circular(20));
  static final BorderRadius pillRadius = BorderRadius.circular(8.0);

  // --- Animation Timings ---
  static const Duration animQuick = Duration(milliseconds: 300);
  static const Duration animStandard = Duration(milliseconds: 400);

  // Parameterized and slowed down layout physics
  static const Duration layoutDuration = Duration(milliseconds: 300);
  static const Curve layoutCurve = Curves.easeInOutQuart;
}