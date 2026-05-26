class GroupConfig {
  final String id;
  final String name;
  final String subtitle;
  final bool isLocked;

  GroupConfig({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'isLocked': isLocked,
    };
  }

  factory GroupConfig.fromMap(Map<String, dynamic> map) {
    return GroupConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subtitle: map['subtitle'] ?? '',
      isLocked: map['isLocked'] ?? false,
    );
  }

  // FIXED: Added String? id to the parameters so the sanitizer can repair corrupted IDs
  GroupConfig copyWith({String? id, String? name, String? subtitle}) {
    return GroupConfig(
      id: id ?? this.id, // Now accepts the repaired ID
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      isLocked: isLocked,
    );
  }
}