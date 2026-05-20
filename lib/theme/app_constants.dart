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

  // --- Sticky Header Constants ---
  static const double headerFontSize = 18.0;
  static const double headerBottomPadding = 8.0;

  // --- Card Internal Layout ---
  static const double cardTopPadding = 18.0;
  static const double borderWidth = 1.0;
  static const int maxTitleLines = 6;
  static const double titleFontSize = 16.0;
  static const double titleLineHeight = 1.25;

  // --- Badge Layout ---
  static const double badgeHeight = 19.0;
  static const double badgeHorizontalPadding = 10.0;
  static const double badgeBorderRadius = 10.0;
  static const double badgeIconSize = 11.0;
  static const double badgeIconGap = 4.0;
  static const double badgeFontSize = 11.0;
}

class AppPhysics {
  // 1. Layout
  static const double menuWidth = 0.45;
  static const double deleteSlotRatio = 0.30;
  static const double editSlotRatio = 0.70;
  static const double checkoutThreshold = 0.45;
  static const double swipeExecuteThreshold = 0.65; // NEW: 65% of screen required to execute left swipe

  // 2. Friction & Resistance
  static const double frictionYield = 0.70;

  // 3. Momentum Prediction (Replaces rigid Flick limits)
  static const double momentumMultiplier = 0.07; // Translates velocity into projected distance

  // 4. Elastic Spring Physics (For snapping back or opening menu)
  static const double springMass = 1.0;
  static const double springStiffness = 400.0;
  static const double springDamping = 28.0;

  // 5. Visuals
  static const double swallowSpeed = 1.3;
  static const double continuousSwallowSpeed = 2.3;

  //6. Glide Physics
  static const double glideStiffness = 120.0; // Increased from 20 to make it exit much faster
  static const double glideDamping = 20.0;
}

class AppLayout {
  static const double headerHeight = 44.0; // Standard iOS/Native header height
  static const double cardBaseHeight = 56.0; // Base height of the ListItemCard
  static const double attributeRowHeight = 20.0; // Height per line of wrapped text/tags
  static const double cardMargin = 12.0; // Bottom margin spacing
}