// Location: lib/models/list_item.dart

class ListItem {
  final String id;
  final String title;
  final List<String> attributeRows;

  // --- Store-Routing & Grouping Schema (Section 9.1) ---
  final String category; // Classification mapping to store aisles (e.g., "Produce")
  final String type; // Primary assigned Shop String or ID (e.g., "Costco")
  final List<String> locations; // Secondary supported stores

  // --- State flags ---
  final bool isCompleted;
  final bool isDeleted;

  // --- Layout Geometry ---
  // Math-Driven Multi-line Wrapping factor (0 to 5)
  final int nWrap;

  // --- Fractional Multi-Indexing ---
  final double shopOrder;
  final double categoryOrder;
  final double globalCustomOrder;

  ListItem({
    required this.id,
    required this.title,
    this.attributeRows = const [],
    this.category = "Uncategorized",
    this.type = "Generic",
    this.locations = const [],
    this.isCompleted = false,
    this.isDeleted = false,
    this.nWrap = 0, // Default to 1-line (0 wraps)
    this.shopOrder = 0.0,
    this.categoryOrder = 0.0,
    this.globalCustomOrder = 0.0,
  });

  ListItem copyWith({
    String? id,
    String? title,
    List<String>? attributeRows,
    String? category,
    String? type,
    List<String>? locations,
    bool? isCompleted,
    bool? isDeleted,
    int? nWrap,
    double? shopOrder,
    double? categoryOrder,
    double? globalCustomOrder,
  }) {
    return ListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      attributeRows: attributeRows ?? this.attributeRows,

      // Included new schema variables in the copyWith method
      category: category ?? this.category,
      type: type ?? this.type,
      locations: locations ?? this.locations,

      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      nWrap: nWrap ?? this.nWrap,
      shopOrder: shopOrder ?? this.shopOrder,
      categoryOrder: categoryOrder ?? this.categoryOrder,
      globalCustomOrder: globalCustomOrder ?? this.globalCustomOrder,
    );
  }
}