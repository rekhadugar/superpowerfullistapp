import 'list_type.dart';

class MacroList {
  final String id;
  final String name;
  final ListType type;
  final DateTime createdAt;

  MacroList({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  // Ready for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Ready for Firestore
  factory MacroList.fromMap(Map<String, dynamic> map) {
    return MacroList(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed List',
      type: ListType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ListType.shopping,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}