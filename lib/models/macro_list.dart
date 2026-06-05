class MacroList {
  final String id;
  final String name;
  final String typeId;
  final double displayOrder;
  final DateTime createdAt;
  final List<String> editors;
  final int activeItemCount; // NEW: Denormalized counter for NoSQL optimization

  MacroList({
    required this.id,
    required this.name,
    required this.typeId,
    this.displayOrder = 100.0,
    required this.createdAt,
    required this.editors,
    this.activeItemCount = -1, // -1 acts as the "unmigrated/legacy" flag
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'typeId': typeId,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
      'editors': editors,
      'activeItemCount': activeItemCount,
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
      editors: List<String>.from(map['editors'] ?? []),
      activeItemCount: map['activeItemCount'] ?? -1,
    );
  }

  MacroList copyWith({
    String? name,
    String? typeId,
    double? displayOrder,
    List<String>? editors,
    int? activeItemCount,
  }) {
    return MacroList(
      id: id,
      name: name ?? this.name,
      typeId: typeId ?? this.typeId,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
      editors: editors ?? this.editors,
      activeItemCount: activeItemCount ?? this.activeItemCount,
    );
  }
}