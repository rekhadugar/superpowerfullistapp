// Location: lib/engine/sticky_header_engine.dart

import '../theme/app_constants.dart';
import '../models/list_item.dart';

// Moved from MainScreen: A pure data class for the engine's output
class PhantomHeaderData {
  final String? title;
  final double yOffset;
  const PhantomHeaderData({this.title, this.yOffset = 0.0});
}

class StickyHeaderEngine {
  /// BATCH 1: O(N) Spatial Cache Builder
  /// Calculates the absolute Y-coordinates for every item based on strict UI constants.
  static List<double> calculateSpatialCache(List<dynamic> displayList) {
    final List<double> offsets = [];
    double currentY = 0.0;

    for (var item in displayList) {
      offsets.add(currentY);

      if (item is String) {
        currentY += AppConstants.headerHeight;
      } else if (item is ListItem) {
        // 1. Base Height + Title Wraps
        double cardHeight = AppConstants.baseCardHeight +
            (item.nWrap * AppConstants.nameWrapHeightStep);

        // 2. Context Badge Row (Type or Category, always 1 row)
        cardHeight += AppConstants.attributeRowHeight;

        // 3. Dynamic Tag Rows
        cardHeight += (item.nTagRows * AppConstants.attributeRowHeight);

        // 4. Margins (Strictly 0.0)
        cardHeight += AppConstants.cardMargin;

        currentY += cardHeight;
      }
    }
    return offsets;
  }

  /// BATCH 2: O(log N) Collision & Search Engine
  /// Fires at 120Hz during scroll. Uses binary search to find the active header
  /// and calculates exact push-up collision math for the phantom render.
  static PhantomHeaderData calculatePhantomHeader(
      double scrollOffset,
      List<double> offsets,
      List<dynamic> displayList,
      ) {
    // Edge case: Scrolled past top or empty list
    if (offsets.isEmpty || scrollOffset <= 0) {
      return const PhantomHeaderData(title: null, yOffset: 0.0);
    }

    // 1. O(log N) Binary Search to find the currently visible index
    int activeIndex = 0;
    int low = 0;
    int high = offsets.length - 1;

    while (low <= high) {
      int mid = low + ((high - low) >> 1);
      if (offsets[mid] <= scrollOffset) {
        activeIndex = mid;
        low = mid + 1; // Look higher
      } else {
        high = mid - 1; // Look lower
      }
    }

    // 2. Walk backward from the active index to find the ruling Section Header
    String? currentHeaderTitle;
    for (int i = activeIndex; i >= 0; i--) {
      if (displayList[i] is String) {
        currentHeaderTitle = displayList[i];
        break;
      }
    }

    // 3. Walk forward to find the next Section Header for the collision push-up
    double pushOffset = 0.0;
    for (int i = activeIndex + 1; i < displayList.length; i++) {
      if (displayList[i] is String) {
        final nextHeaderY = offsets[i];
        final distanceToNextHeader = nextHeaderY - scrollOffset;

        if (distanceToNextHeader < AppConstants.headerHeight) {
          pushOffset = distanceToNextHeader - AppConstants.headerHeight;
        }
        break;
      }
    }

    return PhantomHeaderData(
      title: currentHeaderTitle,
      yOffset: pushOffset,
    );
  }
}