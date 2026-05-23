class SmartItem {
  final String title;
  final String category;
  final String store;
  final String unit;

  const SmartItem({
    required this.title,
    required this.category,
    required this.store,
    required this.unit,
  });
}

class MockDictionary {
  static const List<SmartItem> globalItems = [
    // Produce
    SmartItem(title: 'Apples', category: 'Produce', store: 'Grocery', unit: 'lbs'),
    SmartItem(title: 'Bananas', category: 'Produce', store: 'Grocery', unit: 'pcs'),
    SmartItem(title: 'Avocados', category: 'Produce', store: 'Grocery', unit: 'pcs'),
    SmartItem(title: 'Onions', category: 'Produce', store: 'Grocery', unit: 'lbs'),

    // Dairy & Eggs
    SmartItem(title: 'Milk', category: 'Dairy', store: 'Grocery', unit: 'gal'),
    SmartItem(title: 'Eggs', category: 'Dairy', store: 'Grocery', unit: 'box'),
    SmartItem(title: 'Butter', category: 'Dairy', store: 'Grocery', unit: 'pcs'),
    SmartItem(title: 'Cheese', category: 'Dairy', store: 'Grocery', unit: 'oz'),

    // Bakery & Pantry
    SmartItem(title: 'Bread', category: 'Bakery', store: 'Grocery', unit: 'pcs'),
    SmartItem(title: 'Rice', category: 'Pantry', store: 'Grocery', unit: 'lbs'),
    SmartItem(title: 'Pasta', category: 'Pantry', store: 'Grocery', unit: 'box'),
    SmartItem(title: 'Olive Oil', category: 'Pantry', store: 'Grocery', unit: 'oz'),

    // Meat & Protein
    SmartItem(title: 'Chicken Breast', category: 'Meat', store: 'Grocery', unit: 'lbs'),
    SmartItem(title: 'Ground Beef', category: 'Meat', store: 'Grocery', unit: 'lbs'),

    // Household & Pharmacy
    SmartItem(title: 'Paper Towels', category: 'Household', store: 'Any', unit: 'pk'),
    SmartItem(title: 'Toilet Paper', category: 'Household', store: 'Any', unit: 'pk'),
    SmartItem(title: 'Toothpaste', category: 'Personal Care', store: 'Pharmacy', unit: 'pcs'),
    SmartItem(title: 'Ibuprofen', category: 'Medicine', store: 'Pharmacy', unit: 'box'),
  ];
}