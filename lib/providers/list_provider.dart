// Location: lib/providers/list_provider.dart

import 'package:flutter/material.dart';
import '../engine/sticky_header_engine.dart';
import '../models/list_item.dart';
import '../theme/app_constants.dart';

class ListProvider extends ChangeNotifier {
  double _viewportWidth = 0.0;

  // Added mock categories to support the grouping architecture
  final List<ListItem> _items = [
    // ==========================================
    // CATEGORY 1: Hardware Store (7 Items)
    // ==========================================
    ListItem(
      id: 'hw_1',
      category: 'Hardware Store',
      title: 'Matte Polycrylic Finish',
      attributeRows: ['1 Gallon container', 'For 96.5-inch desk top coat'],
      globalCustomOrder: 1.0,
    ),
    ListItem(
      id: 'hw_2',
      category: 'Hardware Store',
      title: 'Drywall Patching Compound',
      attributeRows: ['Quick dry', 'Wall safe removal repair'],
      globalCustomOrder: 2.0,
    ),
    ListItem(
      id: 'hw_3',
      category: 'Hardware Store',
      title: 'Eggshell White Paint',
      attributeRows: ['Interior walls', 'Standard sheen'],
      globalCustomOrder: 3.0,
    ),
    ListItem(
      id: 'hw_4',
      category: 'Hardware Store',
      title: 'Samsung HW-Q750B Mounting Hardware',
      attributeRows: ['Keyhole mounts required', 'Satellite speakers'],
      globalCustomOrder: 4.0,
    ),
    ListItem(
      id: 'hw_5',
      category: 'Hardware Store',
      title: 'Govee LED Light Strips',
      attributeRows: ['RGBIC', '16.4 ft length', 'Matter compatible'],
      globalCustomOrder: 5.0,
    ),
    ListItem(
      id: 'hw_6',
      category: 'Hardware Store',
      title: 'Painter\'s Tape',
      attributeRows: ['Blue', 'Precision edging for accent wall'],
      globalCustomOrder: 6.0,
    ),
    ListItem(
      id: 'hw_7',
      category: 'Hardware Store',
      title: 'myQ Garage Controller Hub',
      attributeRows: ['Smart home integration'],
      globalCustomOrder: 7.0,
    ),

    // ==========================================
    // CATEGORY 2: Groceries & Food (7 Items)
    // ==========================================
    ListItem(
      id: 'gro_1',
      category: 'Groceries & Food',
      title: 'Kung Pao Sauce',
      attributeRows: ['Spicy profile', 'Panda Express style copycat'],
      globalCustomOrder: 8.0,
    ),
    ListItem(
      id: 'gro_2',
      category: 'Groceries & Food',
      title: 'Extra Firm Tofu',
      attributeRows: ['Protein substitute', 'For Thai stir-fry'],
      globalCustomOrder: 9.0,
    ),
    ListItem(
      id: 'gro_3',
      category: 'Groceries & Food',
      title: 'Pizza Dough',
      attributeRows: ['Thin crust', 'Fresh bakery section'],
      globalCustomOrder: 10.0,
    ),
    ListItem(
      id: 'gro_4',
      category: 'Groceries & Food',
      title: 'Alfredo Sauce',
      attributeRows: ['Creamy garlic base', 'Substitute for tomato pizza sauce'],
      globalCustomOrder: 11.0,
    ),
    ListItem(
      id: 'gro_5',
      category: 'Groceries & Food',
      title: 'Chicken Breast',
      attributeRows: ['Boneless & Skinless', 'Bulk pack'],
      globalCustomOrder: 12.0,
    ),
    ListItem(
      id: 'gro_6',
      category: 'Groceries & Food',
      title: 'Nawabi Biryani Spice Mix',
      attributeRows: ['Hot spice level', 'Hyderabad style'],
      globalCustomOrder: 13.0,
    ),
    ListItem(
      id: 'gro_7',
      category: 'Groceries & Food',
      title: 'Sriracha Hot Chili Sauce',
      attributeRows: ['Large bottle', 'Check Asian foods aisle'],
      globalCustomOrder: 14.0,
    ),

    // ==========================================
    // CATEGORY 3: App Development (5 Items)
    // ==========================================
    ListItem(
      id: 'dev_1',
      category: 'App Development',
      title: 'Setup Firestore Schema',
      attributeRows: ['NoSQL Database', 'Define collections & documents'],
      globalCustomOrder: 15.0,
    ),
    ListItem(
      id: 'dev_2',
      category: 'App Development',
      title: 'Implement Drag and Drop',
      attributeRows: ['React Native / Flutter translation', 'O(1) Spatial Cache reordering'],
      globalCustomOrder: 16.0,
    ),
    ListItem(
      id: 'dev_3',
      category: 'App Development',
      title: 'Cross-platform Sharing API',
      attributeRows: ['Collaboration links', 'Real-time sync listeners'],
      globalCustomOrder: 17.0,
    ),
    ListItem(
      id: 'dev_4',
      category: 'App Development',
      title: 'Math-Driven Sticky Headers',
      attributeRows: ['Phantom header rendering', 'Y-offset cumulative array map', 'Transform.translate constraints'],
      globalCustomOrder: 18.0,
    ),
    ListItem(
      id: 'dev_5',
      category: 'App Development',
      title: 'Update Git Commit Ledger',
      attributeRows: ['Documentation phase'],
      globalCustomOrder: 19.0,
    ),

    // ==========================================
    // CATEGORY 4: Travel & Planning (5 Items)
    // ==========================================
    ListItem(
      id: 'tvl_1',
      category: 'Travel & Planning',
      title: 'Book Downtown Hotel',
      attributeRows: ['Chicago area', '2 Queen Beds', 'Non-smoking'],
      globalCustomOrder: 20.0,
    ),
    ListItem(
      id: 'tvl_2',
      category: 'Travel & Planning',
      title: 'Reserve Rental Boat',
      attributeRows: ['Glacier National Park', 'Apgar area dock', 'Sign risk acknowledgment'],
      globalCustomOrder: 21.0,
    ),
    ListItem(
      id: 'tvl_3',
      category: 'Travel & Planning',
      title: 'Wisconsin Dells Resort',
      attributeRows: ['Indoor waterpark access', 'Family suite'],
      globalCustomOrder: 22.0,
    ),
    ListItem(
      id: 'tvl_4',
      category: 'Travel & Planning',
      title: 'Bloomington Accommodations',
      attributeRows: ['Near Mall of America', 'Attraction bundles included'],
      globalCustomOrder: 23.0,
    ),
    ListItem(
      id: 'tvl_5',
      category: 'Travel & Planning',
      title: 'Las Vegas Strip Casino',
      attributeRows: ['Tower room booking', 'Non-smoking preference'],
      globalCustomOrder: 24.0,
    ),

    // ==========================================
    // CATEGORY 5: Financial & Personal (6 Items)
    // ==========================================
    ListItem(
      id: 'fin_1',
      category: 'Financial & Personal',
      title: 'Analyze Bilt Rewards',
      attributeRows: ['Silver Status check', 'Recurring expense opportunity cost'],
      globalCustomOrder: 25.0,
    ),
    ListItem(
      id: 'fin_2',
      category: 'Financial & Personal',
      title: 'Review Fundrise Portfolio',
      attributeRows: ['Real estate allocation', 'Venture capital distribution'],
      globalCustomOrder: 26.0,
    ),
    ListItem(
      id: 'fin_3',
      category: 'Financial & Personal',
      title: 'Condominium Insurance Transition',
      attributeRows: ['Compare coverage limits', 'Deductibles assessment', 'Premium cost analysis'],
      globalCustomOrder: 27.0,
    ),
    ListItem(
      id: 'fin_4',
      category: 'Financial & Personal',
      title: 'Optimize FPS Aim Mechanics',
      attributeRows: ['Controller response curves', 'Hardware adapter testing'],
      globalCustomOrder: 28.0,
    ),
    ListItem(
      id: 'fin_5',
      category: 'Financial & Personal',
      title: 'Order Thermal Underwear',
      attributeRows: ['Wayfair / Amazon', 'Winter preparation'],
      globalCustomOrder: 29.0,
    ),
    ListItem(
      id: 'fin_6',
      category: 'Financial & Personal',
      title: 'Purchase Kids Bicycle',
      attributeRows: ['Check sizing for Viaan'],
      globalCustomOrder: 30.0,
    ),
  ];

  // --- Gesture State Coordination ---
  final ValueNotifier<String?> openSwipeItemId = ValueNotifier(null);

  // --- SPATIAL CACHE (For Math-Driven Sticky Headers) ---
  final List<double> cumulativeYOffsets = [];
  double totalListHeight = 0.0;
  final List<dynamic> displayList = [];

  ListProvider() {
    _buildDisplayList();
  }

  List<ListItem> get activeItems {
    final filtered = _items.where((item) => !item.isDeleted && !item.isCompleted).toList();
    filtered.sort((a, b) => a.globalCustomOrder.compareTo(b.globalCustomOrder));
    return filtered;
  }

  void updateViewportWidth(double width) {
    if (_viewportWidth != width && width > 0) {
      _viewportWidth = width;
      _recalculateWraps();
    }
  }

  void _recalculateWraps() {
    bool stateChanged = false;

    final double textWidth = _viewportWidth -
        (AppConstants.horizontalPadding * 2) -
        AppConstants.leadingBlockWidth -
        (AppConstants.interElementGap * 2) -
        AppConstants.trailingBlockWidth;
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

    // If wraps changed, rebuild the list and spatial cache
    if (stateChanged) {
      _buildDisplayList();
      notifyListeners();
    }
  }

  // --- SPATIAL CACHE & DISPLAY LOGIC ---

  void _buildDisplayList() {
    displayList.clear();

    final Map<String, List<ListItem>> groupedItems = {};
    for (var item in activeItems) {
      groupedItems.putIfAbsent(item.category, () => []).add(item);
    }

    for (var entry in groupedItems.entries) {
      displayList.add(entry.key);
      displayList.addAll(entry.value);
    }

    _recalculateYOffsets();
  }

  void _recalculateYOffsets() {
    cumulativeYOffsets.clear();
    // CLEAN ARCHITECTURE: Delegate all mathematical calculations to the Engine
    final calculatedOffsets = StickyHeaderEngine.calculateSpatialCache(displayList);
    cumulativeYOffsets.addAll(calculatedOffsets);

    if (cumulativeYOffsets.isNotEmpty) {
      // Estimate total height if needed, though mostly handled by Flutter's scroll bounds
      totalListHeight = cumulativeYOffsets.last;
    }
  }

  void toggleCompletion(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isCompleted: !_items[index].isCompleted);
      // Rebuild the flat list when an item is removed
      _buildDisplayList();
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
      _recalculateWraps();
    }
  }

  void deleteItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isDeleted: true);
      // Rebuild the flat list when an item is removed
      _buildDisplayList();
      notifyListeners();
    }
  }
}