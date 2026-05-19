// Location: lib/services/sticky_header_engine.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/list_provider.dart';

class StickyHeaderState {
  final String title;
  final double dockY;
  final double pushOffset;

  StickyHeaderState({
    required this.title,
    this.dockY = 0.0,
    this.pushOffset = 0.0
  });
}

class StickyHeaderEngine {
  /// Calculates the exact physics for the Phantom Sticky Header.
  static void calculate({
    required BuildContext context,
    required bool isMounted,
    required GlobalKey stackKey,
    required GlobalKey appBarKey,
    required GlobalKey phantomHeaderKey,
    required GlobalKey endOfListKey,
    required Map<String, GlobalKey> headerKeys,
    required ValueNotifier<StickyHeaderState> headerState,
  }) {
    if (!isMounted || stackKey.currentContext == null) return;

    final RenderBox stackBox = stackKey.currentContext!.findRenderObject() as RenderBox;
    final double stackTopY = stackBox.localToGlobal(Offset.zero).dy;

    double appBarBottomY = stackTopY;
    if (appBarKey.currentContext != null) {
      final RenderBox appBarBox = appBarKey.currentContext!.findRenderObject() as RenderBox;
      const double opticalNudge = -1.0;
      // FIXED: Removed overscrollY. localToGlobal inherently includes the scroll offset.
      appBarBottomY = appBarBox.localToGlobal(Offset.zero).dy + opticalNudge;
    }

    final double pinY = math.max(stackTopY, appBarBottomY);

    final listProvider = context.read<ListProvider>();
    final List<String> allHeaders = listProvider.groupedAndSortedItems.whereType<String>().toList();

    if (allHeaders.isEmpty) {
      if (headerState.value.title.isNotEmpty) {
        headerState.value = StickyHeaderState(title: '');
      }
      return;
    }

    String activeHeader = '';
    String? nextHeader;
    double nextHeaderY = double.infinity;
    int lastSeenAboveIndex = -1;

    for (int i = 0; i < allHeaders.length; i++) {
      final String headerTitle = allHeaders[i];
      final GlobalKey? key = headerKeys[headerTitle];

      if (key != null && key.currentContext != null) {
        final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
        // FIXED: Removed overscrollY.
        final dy = box.localToGlobal(Offset.zero).dy;

        if (dy <= pinY + 1.0) {
          lastSeenAboveIndex = i;
        } else {
          nextHeader = headerTitle;
          nextHeaderY = dy;
          if (i > 0) activeHeader = allHeaders[i - 1];
          break;
        }
      }
    }

    if (nextHeader == null && lastSeenAboveIndex != -1) {
      activeHeader = allHeaders[lastSeenAboveIndex];
    }

    double pushOffset = 0.0;
    double stickyHeight = 56.0;
    if (phantomHeaderKey.currentContext != null) {
      stickyHeight = (phantomHeaderKey.currentContext!.findRenderObject() as RenderBox).size.height;
    }

    if (nextHeader != null && nextHeaderY < pinY + stickyHeight) {
      pushOffset = nextHeaderY - (pinY + stickyHeight);
    } else if (nextHeader == null && endOfListKey.currentContext != null) {
      final RenderBox endBox = endOfListKey.currentContext!.findRenderObject() as RenderBox;
      // FIXED: Removed overscrollY.
      final double endDy = endBox.localToGlobal(Offset.zero).dy;
      if (endDy < pinY + stickyHeight) {
        pushOffset = endDy - (pinY + stickyHeight);
      }
    }

    final double dockY = pinY - stackTopY;

    if (headerState.value.title != activeHeader ||
        headerState.value.dockY != dockY ||
        headerState.value.pushOffset != pushOffset) {
      headerState.value = StickyHeaderState(
          title: activeHeader,
          dockY: dockY,
          pushOffset: pushOffset
      );
    }
  }
}