// Location: lib/models/list_item.dart

class ListItem {
  final String id;
  final String title;
  final List<String> attributeRows;

  // State flags
  final bool isCompleted;
  final bool isDeleted;

  // New: Math-Driven Multi-line Wrapping factor (0 to 5)
  final int nWrap;

  // Fractional Multi-Indexing
  final double shopOrder;
  final double categoryOrder;
  final double globalCustomOrder;

  ListItem({
    required this.id,
    required this.title,
    this.attributeRows = const [],
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
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      nWrap: nWrap ?? this.nWrap,
      shopOrder: shopOrder ?? this.shopOrder,
      categoryOrder: categoryOrder ?? this.categoryOrder,
      globalCustomOrder: globalCustomOrder ?? this.globalCustomOrder,
    );
  }
}