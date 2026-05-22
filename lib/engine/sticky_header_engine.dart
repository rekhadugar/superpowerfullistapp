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
  /// Calculates the absolute Y-coordinates, now scaled dynamically by the device font size.
  static List<double> calculateSpatialCache(List<dynamic> displayList, {double textScaleFactor = 1.0}) {
    final List<double> offsets = [];
    double currentY = 0.0;

    for (var item in displayList) {
      offsets.add(currentY);

      if (item is String) {
        currentY += (AppConstants.headerHeight * textScaleFactor);
      } else if (item is ListItem) {
        // 1. Base Height + Title Wraps (Scaled)
        double cardHeight = (AppConstants.baseCardHeight * textScaleFactor) +
            (item.nWrap * (AppConstants.nameWrapHeightStep * textScaleFactor));

        // 2. Context Badge Row (Scaled)
        cardHeight += (AppConstants.attributeRowHeight * textScaleFactor);

        // 3. Dynamic Tag Rows (Scaled)
        cardHeight += (item.nTagRows * (AppConstants.attributeRowHeight * textScaleFactor));

        // 4. Margins (Strictly 0.0, scaling 0 is 0)
        cardHeight += AppConstants.cardMargin;

        currentY += cardHeight;
      }
    }
    return offsets;
  }

  /// BATCH 2: O(log N) Collision & Search Engine
  static PhantomHeaderData calculatePhantomHeader(
      double scrollOffset,
      List<double> offsets,
      List<dynamic> displayList,
      {double textScaleFactor = 1.0}
      ) {
    if (offsets.isEmpty || scrollOffset <= 0) {
      return const PhantomHeaderData(title: null, yOffset: 0.0);
    }

    int activeIndex = 0;
    int low = 0;
    int high = offsets.length - 1;

    while (low <= high) {
      int mid = low + ((high - low) >> 1);
      if (offsets[mid] <= scrollOffset) {
        activeIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    String? currentHeaderTitle;
    for (int i = activeIndex; i >= 0; i--) {
      if (displayList[i] is String) {
        currentHeaderTitle = displayList[i];
        break;
      }
    }

    double pushOffset = 0.0;
    final double scaledHeaderHeight = AppConstants.headerHeight * textScaleFactor;

    for (int i = activeIndex + 1; i < displayList.length; i++) {
      if (displayList[i] is String) {
        final nextHeaderY = offsets[i];
        final distanceToNextHeader = nextHeaderY - scrollOffset;

        if (distanceToNextHeader < scaledHeaderHeight) {
          pushOffset = distanceToNextHeader - scaledHeaderHeight;
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