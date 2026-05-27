class ListItem {
  final String id;
  final String title;
  final List<String> attributeRows;

  // --- Store-Routing & Grouping Schema ---
  final String category;
  final String type;
  final List<String> locations;
  final List<String> excludedLocations; // NEW: The Banish List

  // --- State flags ---
  final bool isCompleted;
  final bool isDeleted;
  final DateTime? completedAt;

  // --- Item Quantity ---
  final int quantity;
  final String unit;

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
    this.excludedLocations = const [], // NEW
    this.isCompleted = false,
    this.isDeleted = false,
    this.completedAt,
    this.quantity = 0,
    this.unit = 'pcs',
    this.nWrap = 0,
    this.nTagRows = 0,
    this.typeOrder = 0.0,
    this.categoryOrder = 0.0,
    this.globalCustomOrder = 0.0,
  });

  ListItem copyWith({
    String? id, // FIXED: Added id parameter for copying items
    String? title,
    List<String>? attributeRows,
    String? category,
    String? type,
    List<String>? locations,
    List<String>? excludedLocations,
    bool? isCompleted,
    bool? isDeleted,
    DateTime? completedAt,
    int? quantity,
    String? unit,
    int? nWrap,
    int? nTagRows,
    double? typeOrder,
    double? categoryOrder,
    double? globalCustomOrder,
  }) {
    return ListItem(
      id: id ?? this.id, // FIXED: Uses the new id if provided, otherwise falls back to current
      title: title ?? this.title,
      attributeRows: attributeRows ?? this.attributeRows,
      category: category ?? this.category,
      type: type ?? this.type,
      locations: locations ?? this.locations,
      excludedLocations: excludedLocations ?? this.excludedLocations,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      completedAt: completedAt ?? this.completedAt,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      nWrap: nWrap ?? this.nWrap,
      nTagRows: nTagRows ?? this.nTagRows,
      typeOrder: typeOrder ?? this.typeOrder,
      categoryOrder: categoryOrder ?? this.categoryOrder,
      globalCustomOrder: globalCustomOrder ?? this.globalCustomOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'attributeRows': attributeRows,
      'category': category,
      'type': type,
      'locations': locations,
      'excludedLocations': excludedLocations, // NEW
      'isCompleted': isCompleted,
      'isDeleted': isDeleted,
      'completedAt': completedAt?.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
      'nWrap': nWrap,
      'nTagRows': nTagRows,
      'typeOrder': typeOrder,
      'categoryOrder': categoryOrder,
      'globalCustomOrder': globalCustomOrder,
    };
  }

  factory ListItem.fromMap(Map<String, dynamic> map) {
    return ListItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      attributeRows: List<String>.from(map['attributeRows'] ?? []),
      category: map['category'] ?? 'Everything Else',
      type: map['type'] ?? 'Any',
      locations: List<String>.from(map['locations'] ?? []),
      excludedLocations: List<String>.from(map['excludedLocations'] ?? []), // NEW
      isCompleted: map['isCompleted'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
      quantity: map['quantity']?.toInt() ?? 0,
      unit: map['unit'] ?? 'pcs',
      nWrap: map['nWrap']?.toInt() ?? 0,
      nTagRows: map['nTagRows']?.toInt() ?? 0,
      typeOrder: (map['typeOrder'] ?? 0.0).toDouble(),
      categoryOrder: (map['categoryOrder'] ?? 0.0).toDouble(),
      globalCustomOrder: (map['globalCustomOrder'] ?? 0.0).toDouble(),
    );
  }
}