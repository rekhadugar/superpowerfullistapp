class StoreConfig {
  final String id;
  final String name;
  final String address;
  final bool isLocked; // Protects the "Any" default

  StoreConfig({
    required this.id,
    required this.name,
    this.address = '',
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'isLocked': isLocked,
    };
  }

  factory StoreConfig.fromMap(Map<String, dynamic> map) {
    return StoreConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      isLocked: map['isLocked'] ?? false,
    );
  }

  StoreConfig copyWith({String? name, String? address}) {
    return StoreConfig(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      isLocked: isLocked,
    );
  }
}

class CategoryConfig {
  final String id;
  final String name;
  final bool isLocked; // Protects the "Everything Else" default

  CategoryConfig({
    required this.id,
    required this.name,
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isLocked': isLocked,
    };
  }

  factory CategoryConfig.fromMap(Map<String, dynamic> map) {
    return CategoryConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isLocked: map['isLocked'] ?? false,
    );
  }

  CategoryConfig copyWith({String? name}) {
    return CategoryConfig(
      id: id,
      name: name ?? this.name,
      isLocked: isLocked,
    );
  }
}