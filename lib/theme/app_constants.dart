class AppConstants {
  // Strict Math-Driven Heights
  static const double headerHeight = 44.0;
  static const double baseCardHeight = 56.0;
  static const double attributeRowHeight = 25.0; // Increased to 25px for visual breathing room
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

  // --- Viewport Clearance ---
  static const double listTopPadding = 0.0;
  static const double listBottomClearance = 100.0; // Standard clearance for bottom nav
  static const double batchModeBottomClearance = 300.0; // Extended clearance when batch menu is open
  static const double snackbarBottomMargin = 16.0;
}

class AppPhysics {
  // 1. Core Layout & Thresholds (TWEAK THESE)
  static const double menuWidth = 0.45;              // How far the menu opens initially
  static const double swipeExecuteThreshold = 0.60;  // Distance required to trigger left-swipe Delete
  static const double checkoutThreshold = 0.45;      // Distance required to trigger right-swipe Checkout

  static const double deleteSlotRatio = 0.30;        // Initial size of the Red box
  static const double editSlotRatio = 0.70;          // Initial size of the Blue box

  // 2. Friction & Resistance (TWEAK THESE)
  static const double frictionYield = 0.50;          // Rubber-banding when dragged past thresholds (1.0 = slippery, 0.1 = stiff)
  static const double momentumMultiplier = 0.06;     // Translates flick velocity into projected distance

  // 3. Elastic Spring Physics (For snapping back or opening menu)
  static const double springMass = 1.0;
  static const double springStiffness = 400.0;
  static const double springDamping = 28.0;

  // 4. Glide Physics (For exiting the screen)
  static const double glideStiffness = 120.0;
  static const double glideDamping = 20.0;
}

class AppLayout {
  static const double headerHeight = 44.0; // Standard iOS/Native header height
  static const double cardBaseHeight = 56.0; // Base height of the ListItemCard
  static const double attributeRowHeight = 20.0; // Height per line of wrapped text/tags
  static const double cardMargin = 12.0; // Bottom margin spacing
}

// --- NEW: The Fluid Geometry Engine ---
// Projects scaled boundaries based on the ThemeProvider's multiplier
class FluidGeometry {
  final double scale;
  const FluidGeometry(this.scale);

  // Core Heights
  double get headerHeight => AppConstants.headerHeight * scale;
  double get baseCardHeight => AppConstants.baseCardHeight * scale;
  double get attributeRowHeight => AppConstants.attributeRowHeight * scale;
  double get nameWrapHeightStep => AppConstants.nameWrapHeightStep * scale;

  // Layout Blocks & Margins
  double get horizontalPadding => AppConstants.horizontalPadding * scale;
  double get leadingBlockWidth => AppConstants.leadingBlockWidth * scale;
  double get trailingBlockWidth => AppConstants.trailingBlockWidth * scale;
  double get interElementGap => AppConstants.interElementGap * scale;

  // Badges & Icons
  double get badgeHeight => AppConstants.badgeHeight * scale;
  double get badgeHorizontalPadding => AppConstants.badgeHorizontalPadding * scale;
  double get badgeIconSize => AppConstants.badgeIconSize * scale;
  double get badgeIconGap => AppConstants.badgeIconGap * scale;
  double get attributeIconSize => AppConstants.attributeIconSize * scale;
  double get iconSize => 24.0 * scale;
}

