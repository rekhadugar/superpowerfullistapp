// Location: lib/providers/list_provider.dart

import 'package:flutter/material.dart';
import '../models/list_item.dart';

class ListProvider extends ChangeNotifier {
  double _viewportWidth = 0.0;

  // Added 'final' to clear the linter warning
  final List<ListItem> _items = [
    ListItem(
      id: 'task_1',
      title: 'Pick up Drywall Compound, Primer, Sandpaper, and the extended cable management routing kit for the desk restoration project',
      attributeRows: ['Aisle 12', 'Project: Desk & Wall Repair'],
      globalCustomOrder: 1.0,
    ),
    ListItem(
      id: 'task_2',
      title: 'Order Tofu & Drunken Noodles',
      attributeRows: ['Pickup at 6:30 PM'],
      globalCustomOrder: 2.0,
    ),
    ListItem(
      id: 'task_3',
      title: 'Nawabi Hyderabad House Catering',
      attributeRows: ['Confirm headcount', 'Check delivery options'],
      globalCustomOrder: 3.0,
    ),
    ListItem(
      id: 'task_4',
      title: 'Mazda CX-5 Wiper Blades',
      attributeRows: ['Check fitment for 2025 model'],
      globalCustomOrder: 4.0,
    ),
    ListItem(
      id: 'task_5',
      title: 'Review Bilt 2.0 Multipliers',
      attributeRows: [],
      globalCustomOrder: 5.0,
    ),
  ];

  // --- Gesture State Coordination ---
  // Tracks the ID of the currently swiped-open item.
  // Wrappers listen to this without triggering a global UI rebuild.
  final ValueNotifier<String?> openSwipeItemId = ValueNotifier(null);

  // Active Filtering
  List<ListItem> get activeItems {
    final filtered = _items.where((item) => !item.isDeleted && !item.isCompleted).toList();
    filtered.sort((a, b) => a.globalCustomOrder.compareTo(b.globalCustomOrder));
    return filtered;
  }

  // Update viewport width and recalculate all wraps
  void updateViewportWidth(double width) {
    if (_viewportWidth != width && width > 0) {
      _viewportWidth = width;
      _recalculateWraps();
    }
  }

  // Off-screen TextPainter pre-calculation based on V2 Specs
  void _recalculateWraps() {
    bool stateChanged = false;

    final double textWidth = _viewportWidth - 108.0;
    if (textWidth <= 0) return;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      final TextPainter tp = TextPainter(
        text: TextSpan(
            text: item.title,
            style: const TextStyle(fontSize: 16.0, height: 1.25)
        ),
        textDirection: TextDirection.ltr,
        maxLines: 6,
      )..layout(maxWidth: textWidth);

      final int lineCount = tp.didExceedMaxLines
          ? 6
          : tp.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: item.title.length)).isNotEmpty
          ? (tp.height / (16.0 * 1.25)).round()
          : 1;

      final int calculatedNWrap = (lineCount - 1).clamp(0, 5);

      if (item.nWrap != calculatedNWrap) {
        _items[i] = item.copyWith(nWrap: calculatedNWrap);
        stateChanged = true;
      }
    }

    if (stateChanged) {
      notifyListeners();
    }
  }

  void toggleCompletion(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isCompleted: !_items[index].isCompleted);
      notifyListeners();
    }
  }

  void editItem(String id, String newTitle, List<String> newAttributes) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        title: newTitle,
        attributeRows: newAttributes,
      );
      // Recalculating wraps will automatically update nWrap and notify listeners
      _recalculateWraps();
    }
  }

  void deleteItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isDeleted: true);
      notifyListeners();
    }
  }
}