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

  // NEW: Chronological Tracking
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
    this.isCompleted = false,
    this.isDeleted = false,
    this.completedAt, // NEW
    this.quantity = 0,
    this.unit = 'pcs',
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
    DateTime? completedAt, // NEW
    int? quantity,
    String? unit,
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
      completedAt: completedAt ?? this.completedAt, // NEW
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      nWrap: nWrap ?? this.nWrap,
      nTagRows: nTagRows ?? this.nTagRows,
      typeOrder: typeOrder ?? this.typeOrder,
      categoryOrder: categoryOrder ?? this.categoryOrder,
      globalCustomOrder: globalCustomOrder ?? this.globalCustomOrder,
    );
  }

  // --- Serialization for Local Storage / Firestore ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'attributeRows': attributeRows,
      'category': category,
      'type': type,
      'locations': locations,
      'isCompleted': isCompleted,
      'isDeleted': isDeleted,
      'completedAt': completedAt?.toIso8601String(), // NEW
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
      isCompleted: map['isCompleted'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null, // NEW
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