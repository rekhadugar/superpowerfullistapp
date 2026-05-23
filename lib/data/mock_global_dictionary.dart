class SmartItem {
  final String title;
  final String category;
  final String store;
  final String unit;
  final List<String> tags; // NEW: Supports learning user tag preferences

  const SmartItem({
    required this.title,
    required this.category,
    required this.store,
    required this.unit,
    this.tags = const [],
  });
}

class MockDictionary {
  static const List<SmartItem> globalItems = [
    // Produce
    SmartItem(title: 'Apples', category: 'Produce', store: 'Grocery', unit: 'lbs', tags: []),
    SmartItem(title: 'Bananas', category: 'Produce', store: 'Grocery', unit: 'pcs', tags: []),
    SmartItem(title: 'Avocados', category: 'Produce', store: 'Grocery', unit: 'pcs', tags: []),
    SmartItem(title: 'Onions', category: 'Produce', store: 'Grocery', unit: 'lbs', tags: []),

    // Dairy & Eggs
    SmartItem(title: 'Milk', category: 'Dairy', store: 'Grocery', unit: 'gal', tags: []),
    SmartItem(title: 'Eggs', category: 'Dairy', store: 'Grocery', unit: 'box', tags: []),
    SmartItem(title: 'Butter', category: 'Dairy', store: 'Grocery', unit: 'pcs', tags: []),
    SmartItem(title: 'Cheese', category: 'Dairy', store: 'Grocery', unit: 'oz', tags: []),

    // Bakery & Pantry
    SmartItem(title: 'Bread', category: 'Bakery', store: 'Grocery', unit: 'pcs', tags: []),
    SmartItem(title: 'Rice', category: 'Pantry', store: 'Grocery', unit: 'lbs', tags: []),
    SmartItem(title: 'Pasta', category: 'Pantry', store: 'Grocery', unit: 'box', tags: []),
    SmartItem(title: 'Olive Oil', category: 'Pantry', store: 'Grocery', unit: 'oz', tags: []),

    // Meat & Protein
    SmartItem(title: 'Chicken Breast', category: 'Meat', store: 'Grocery', unit: 'lbs', tags: []),
    SmartItem(title: 'Ground Beef', category: 'Meat', store: 'Grocery', unit: 'lbs', tags: []),

    // Household & Pharmacy
    SmartItem(title: 'Paper Towels', category: 'Household', store: 'Any', unit: 'pk', tags: []),
    SmartItem(title: 'Toilet Paper', category: 'Household', store: 'Any', unit: 'pk', tags: []),
    SmartItem(title: 'Toothpaste', category: 'Personal Care', store: 'Pharmacy', unit: 'pcs', tags: []),
    SmartItem(title: 'Ibuprofen', category: 'Medicine', store: 'Pharmacy', unit: 'box', tags: []),
  ];
}