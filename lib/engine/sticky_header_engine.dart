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
  /// Calculates the absolute Y-coordinates, now scaled dynamically by FluidGeometry.
  static List<double> calculateSpatialCache(List<dynamic> displayList, {double textScaleFactor = 1.0}) {
    final List<double> offsets = [];
    double currentY = 0.0;

    // FIXED: Instantiate the geometry lens once per layout pass
    final geometry = FluidGeometry(textScaleFactor);

    for (var item in displayList) {
      offsets.add(currentY);

      if (item is String) {
        currentY += geometry.headerHeight;
      } else if (item is ListItem) {
        // 1. Base Height + Title Wraps (Scaled via Geometry)
        double cardHeight = geometry.baseCardHeight +
            (item.nWrap * geometry.nameWrapHeightStep);

        // 2. Context Badge Row (Scaled via Geometry)
        cardHeight += geometry.attributeRowHeight;

        // 3. Dynamic Tag Rows (Scaled via Geometry)
        cardHeight += (item.nTagRows * geometry.attributeRowHeight);

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
    final geometry = FluidGeometry(textScaleFactor);

    for (int i = activeIndex + 1; i < displayList.length; i++) {
      if (displayList[i] is String) {
        final nextHeaderY = offsets[i];
        final distanceToNextHeader = nextHeaderY - scrollOffset;

        if (distanceToNextHeader < geometry.headerHeight) {
          pushOffset = distanceToNextHeader - geometry.headerHeight;
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