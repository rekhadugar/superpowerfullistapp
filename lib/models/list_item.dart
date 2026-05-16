class ListItem {
  final String id;
  final String name;
  bool isCompleted;
  int order;
  int quantity;
  String category;

  ListItem({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.order = 0,
    this.quantity = 1,
    this.category = 'Groceries', // Default fallback
  });

  factory ListItem.fromMap(Map<String, dynamic> data, String documentId) {
    return ListItem(
      id: documentId,
      name: data['name'] ?? 'Unknown Item',
      isCompleted: data['isCompleted'] ?? false,
      order: data['order'] ?? 0,
      quantity: data['quantity'] ?? 1,
      category: data['category'] ?? 'Groceries',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'order': order,
      'quantity': quantity,
      'category': category,
    };
  }
}