import 'package:cloud_firestore/cloud_firestore.dart';

class ListItem {
  final String id;
  final String name;
  bool isCompleted;
  int order;

  // Quantifiable Fields
  int quantity;
  String unit;

  // Relational Fields
  String type;
  String category;
  List<String> locations;
  String context;

  // Audit & Soft Delete Fields
  String? createdBy;
  Timestamp? createdAt;
  String? updatedBy;
  Timestamp? updatedAt;
  bool isDeleted;
  String? deletedBy;
  Timestamp? deletedAt;

  ListItem({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.order = 0,
    this.quantity = 1,
    this.unit = '',
    this.type = 'Groceries',
    this.category = 'Uncategorized',
    this.locations = const ['Anywhere'],
    this.context = '',
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedBy,
    this.deletedAt,
  });

  factory ListItem.fromMap(Map<String, dynamic> data, String documentId) {
    return ListItem(
      id: documentId,
      name: data['name'] ?? 'Unknown Item',
      isCompleted: data['isCompleted'] ?? false,
      order: data['order'] ?? 0,
      quantity: data['quantity'] ?? 1,
      unit: data['unit'] ?? '',
      type: data['type'] ?? 'Groceries',
      category: data['category'] ?? 'Uncategorized',
      locations: List<String>.from(data['locations'] ?? ['Anywhere']),
      context: data['context'] ?? '',
      createdBy: data['createdBy'],
      createdAt: data['createdAt'] as Timestamp?,
      updatedBy: data['updatedBy'],
      updatedAt: data['updatedAt'] as Timestamp?,
      isDeleted: data['isDeleted'] ?? false,
      deletedBy: data['deletedBy'],
      deletedAt: data['deletedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'order': order,
      'quantity': quantity,
      'unit': unit,
      'type': type,
      'category': category,
      'locations': locations,
      'context': context,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt,
    };
  }
}