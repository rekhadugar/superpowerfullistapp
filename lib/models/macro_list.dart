class MacroList {
  final String id;
  final String name;
  final String typeId;
  final double displayOrder;
  final DateTime createdAt; // Restored your original property!

  MacroList({
    required this.id,
    required this.name,
    required this.typeId,
    this.displayOrder = 100.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'typeId': typeId,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MacroList.fromMap(Map<String, dynamic> map) {
    return MacroList(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      typeId: map['typeId'] ?? 'sys_shopping',
      displayOrder: (map['displayOrder'] ?? 100).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  // FIXED: Added the missing copyWith method
  MacroList copyWith({
    String? name,
    String? typeId,
    double? displayOrder,
    DateTime? createdAt,
  }) {
    return MacroList(
      id: id,
      name: name ?? this.name,
      typeId: typeId ?? this.typeId,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}