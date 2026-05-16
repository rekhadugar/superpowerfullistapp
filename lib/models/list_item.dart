class ListItem {
  final String id;
  final String name;
  bool isCompleted;
  int order; // Added to track drag-and-drop position in the cloud

  ListItem({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.order = 0,
  });

  // Factory method: Converts Firestore JSON into a Dart Object
  factory ListItem.fromMap(Map<String, dynamic> data, String documentId) {
    return ListItem(
      id: documentId,
      name: data['name'] ?? 'Unknown Item',
      isCompleted: data['isCompleted'] ?? false,
      order: data['order'] ?? 0,
    );
  }

  // Method: Converts our Dart Object back into Firestore JSON
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'order': order,
    };
  }
}