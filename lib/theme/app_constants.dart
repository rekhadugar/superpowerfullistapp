// Location: lib/theme/app_constants.dart

class AppConstants {
  // Strict Math-Driven Heights
  static const double headerHeight = 44.0;
  static const double baseCardHeight = 56.0;
  static const double attributeRowHeight = 20.0;
  static const double nameWrapHeightStep = 20.0;
  static const double topBarHeight = 76.0;

  // Padding & Margins
  static const double cardMargin = 0.0; // Must remain 0px to preserve O(1) scroll math
  static const double horizontalPadding = 16.0;

  // Internal Card Geometry
  static const double leadingBlockWidth = 32.0;
  static const double trailingBlockWidth = 48.0;
  static const double interElementGap = 12.0;
  static const double attributeIconSize = 14.0;
}

class AppPhysics {
  // 1. Layout
  static const double menuWidth = 0.45;
  static const double deleteSlotRatio = 0.30;
  static const double editSlotRatio = 0.70;

  // 2. Friction & Resistance
  static const double frictionYield = 0.70;
  static const double flickVelocity = 400.0;
  static const double flickMinDistance = 50.0;

  // 3. Animation & Visuals
  static const int snapDurationMs = 400;
  static const double swallowSpeed = 2.3;
  static const double continuousSwallowSpeed = 3.0;
}