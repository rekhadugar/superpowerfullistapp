class ListItem {
  final String id;
  final String title;
  final List<String> attributeRows;

  // --- Store-Routing & Grouping Schema (Section 9.1) ---
  final String category;
  final String type;
  final List<String> locations;

  // --- State flags ---
  final bool isCompleted;
  final bool isDeleted;

  // NEW: Item Quantity
  final int quantity;

  // --- Layout Geometry ---
  final int nWrap;
  final int nTagRows;

  // --- Fractional Multi-Indexing ---
  final double typeOrder;
  final double categoryOrder;
  final double globalCustomOrder;

  ListItem({
    required this.id,
    required this.title,
    this.attributeRows = const [],
    this.category = "Everything Else",
    this.type = "Any",
    this.locations = const [],
    this.isCompleted = false,
    this.isDeleted = false,
    this.quantity = 1, // Default to 1
    this.nWrap = 0,
    this.nTagRows = 0,
    this.typeOrder = 0.0,
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
    int? quantity,
    int? nWrap,
    int? nTagRows,
    double? typeOrder,
    double? categoryOrder,
    double? globalCustomOrder,
  }) {
    return ListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      attributeRows: attributeRows ?? this.attributeRows,
      category: category ?? this.category,
      type: type ?? this.type,
      locations: locations ?? this.locations,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      quantity: quantity ?? this.quantity,
      nWrap: nWrap ?? this.nWrap,
      nTagRows: nTagRows ?? this.nTagRows,
      typeOrder: typeOrder ?? this.typeOrder,
      categoryOrder: categoryOrder ?? this.categoryOrder,
      globalCustomOrder: globalCustomOrder ?? this.globalCustomOrder,
    );
  }
}