import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/list_item.dart';

class StickyHeaderState {
  final String title;
  final double dockY;
  final double pushOffset;
  final double snapDelta;

  StickyHeaderState({
    required this.title,
    this.dockY = 0.0,
    this.pushOffset = 0.0,
    this.snapDelta = 0.0,
  });
}

class StickyHeaderEngine {
  static void calculate({
    required BuildContext context,
    required bool isMounted,
    required GlobalKey stackKey,
    required GlobalKey appBarKey,
    required GlobalKey phantomHeaderKey,
    required GlobalKey endOfListKey,
    required Map<String, GlobalKey> headerKeys,
    required Map<String, GlobalKey> itemKeys,
    required ValueNotifier<StickyHeaderState> headerState,
    required ScrollController scrollController,
    required List<dynamic> flatList,
  }) {
    if (!isMounted || stackKey.currentContext == null) return;

    final List<String> allHeaders = flatList.whereType<String>().toList();

    if (allHeaders.isEmpty) {
      if (headerState.value.title.isNotEmpty) {
        headerState.value = StickyHeaderState(title: '');
      }
      return;
    }

    if (scrollController.hasClients && scrollController.offset <= 0) {
      headerState.value = StickyHeaderState(title: '');
      return;
    }

    final RenderBox stackBox = stackKey.currentContext!.findRenderObject() as RenderBox;
    final double stackTopY = stackBox.localToGlobal(Offset.zero).dy;

    double appBarBottomY = stackTopY;
    if (appBarKey.currentContext != null) {
      final RenderBox appBarBox = appBarKey.currentContext!.findRenderObject() as RenderBox;
      appBarBottomY = appBarBox.localToGlobal(Offset.zero).dy - 1.0;
    }

    final double pinY = math.max(stackTopY, appBarBottomY);

    double stickyHeight = 56.0;
    if (phantomHeaderKey.currentContext != null) {
      stickyHeight = (phantomHeaderKey.currentContext!.findRenderObject() as RenderBox).size.height;
    }

    int? activeElementIndex;

    for (int i = 0; i < flatList.length; i++) {
      final row = flatList[i];
      GlobalKey? key = (row is String) ? headerKeys[row] : itemKeys[(row as ListItem).id];

      if (key?.currentContext != null) {
        final box = key!.currentContext!.findRenderObject() as RenderBox;
        final dy = box.localToGlobal(Offset.zero).dy;

        if (dy <= pinY + 2.0) {
          activeElementIndex = i;
        } else {
          if (activeElementIndex == null) activeElementIndex = i > 0 ? i - 1 : 0;
          break;
        }
      }
    }

    String activeHeader = allHeaders.first;
    int activeHeaderIndex = -1;
    double pushOffset = 0.0;

    if (activeElementIndex != null) {
      for (int i = activeElementIndex; i >= 0; i--) {
        if (flatList[i] is String) {
          activeHeader = flatList[i] as String;
          activeHeaderIndex = i;
          break;
        }
      }

      int nextHeaderIndex = -1;
      if (activeHeaderIndex != -1) {
        for (int i = activeHeaderIndex + 1; i < flatList.length; i++) {
          if (flatList[i] is String) {
            nextHeaderIndex = i;
            break;
          }
        }
      }

      // CUSTOM FIX: Push by the TOP of the last item in the active section
      // This guarantees the Phantom Header is NEVER on screen without an item.
      bool pushedByItem = false;
      int lastItemIndex = nextHeaderIndex != -1 ? nextHeaderIndex - 1 : flatList.length - 1;

      if (lastItemIndex > activeHeaderIndex) {
        final row = flatList[lastItemIndex];
        if (row is ListItem) {
          GlobalKey? lastItemKey = itemKeys[row.id];
          if (lastItemKey?.currentContext != null) {
            final box = lastItemKey!.currentContext!.findRenderObject() as RenderBox;
            final lastItemY = box.localToGlobal(Offset.zero).dy;

            if (lastItemY < pinY + stickyHeight) {
              pushOffset = lastItemY - (pinY + stickyHeight);
              pushedByItem = true;
            }
          }
        }
      }

      // Fallback behavior if the section is empty or last item is unmounted
      if (!pushedByItem) {
        if (nextHeaderIndex != -1) {
          final hKey = headerKeys[flatList[nextHeaderIndex]];
          if (hKey?.currentContext != null) {
            final hBox = hKey!.currentContext!.findRenderObject() as RenderBox;
            final nextHeaderY = hBox.localToGlobal(Offset.zero).dy;
            if (nextHeaderY < pinY + stickyHeight) {
              pushOffset = nextHeaderY - (pinY + stickyHeight);
            }
          }
        } else if (endOfListKey.currentContext != null) {
          final RenderBox endBox = endOfListKey.currentContext!.findRenderObject() as RenderBox;
          final double endDy = endBox.localToGlobal(Offset.zero).dy;
          if (endDy < pinY + stickyHeight) {
            pushOffset = endDy - (pinY + stickyHeight);
          }
        }
      }
    }

    final GlobalKey? activeHeaderKey = headerKeys[activeHeader];
    if (activeHeaderKey?.currentContext != null) {
      final RenderBox box = activeHeaderKey!.currentContext!.findRenderObject() as RenderBox;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy > pinY + 0.5) {
        headerState.value = StickyHeaderState(title: '');
        return;
      }
    }

    double bestSnapDelta = 0.0;
    double minAbsDelta = double.infinity;

    if (scrollController.hasClients && scrollController.offset > 10.0) {
      for (int i = 0; i < flatList.length; i++) {
        final row = flatList[i];
        final isHeader = row is String;
        GlobalKey? key = isHeader ? headerKeys[row] : itemKeys[(row as ListItem).id];

        if (key?.currentContext != null) {
          final box = key!.currentContext!.findRenderObject() as RenderBox;
          final dy = box.localToGlobal(Offset.zero).dy;

          double targetDockLine = isHeader ? pinY : (pinY + stickyHeight);
          double delta = dy - targetDockLine;

          if (delta.abs() < minAbsDelta) {
            minAbsDelta = delta.abs();
            bestSnapDelta = delta;
          }
        }
      }
      if (minAbsDelta > 150.0) {
        bestSnapDelta = 0.0;
      }
    }

    final double dockY = pinY - stackTopY;

    if (headerState.value.title != activeHeader ||
        headerState.value.dockY != dockY ||
        headerState.value.pushOffset != pushOffset ||
        headerState.value.snapDelta != bestSnapDelta) {
      headerState.value = StickyHeaderState(
        title: activeHeader,
        dockY: dockY,
        pushOffset: pushOffset,
        snapDelta: bestSnapDelta,
      );
    }
  }
}