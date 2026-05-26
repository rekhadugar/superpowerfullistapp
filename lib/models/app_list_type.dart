import 'package:flutter/material.dart';

class AppListType {
  final String id;
  final String name;
  final String axis1Label; // e.g., 'Stores', 'Platforms', 'Regions'
  final String axis2Label; // e.g., 'Categories', 'Genres', 'Varietals'
  final int iconCodePoint; // Saves the material icon for SharedPreferences
  final bool isSystem;     // True for core types (prevents deletion)

  const AppListType({
    required this.id,
    required this.name,
    required this.axis1Label,
    required this.axis2Label,
    required this.iconCodePoint,
    this.isSystem = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'axis1Label': axis1Label,
      'axis2Label': axis2Label,
      'iconCodePoint': iconCodePoint,
      'isSystem': isSystem,
    };
  }

  factory AppListType.fromMap(Map<String, dynamic> map) {
    return AppListType(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      axis1Label: map['axis1Label'] ?? 'Group 1',
      axis2Label: map['axis2Label'] ?? 'Group 2',
      iconCodePoint: map['iconCodePoint'] ?? Icons.list.codePoint,
      isSystem: map['isSystem'] ?? false,
    );
  }

  // --- PREDEFINED SYSTEM TYPES ---
  static final AppListType shopping = AppListType(
    id: 'sys_shopping',
    name: 'Shopping',
    axis1Label: 'Stores',
    axis2Label: 'Categories',
    iconCodePoint: Icons.shopping_cart_outlined.codePoint,
    isSystem: true,
  );

  static final AppListType tasks = AppListType(
    id: 'sys_tasks',
    name: 'Tasks & Todos',
    axis1Label: 'Context',
    axis2Label: 'Project',
    iconCodePoint: Icons.check_box_outlined.codePoint,
    isSystem: true,
  );

  static final AppListType movies = AppListType(
    id: 'sys_movies',
    name: 'Movies & TV',
    axis1Label: 'Platform',
    axis2Label: 'Genre',
    iconCodePoint: Icons.movie_creation_outlined.codePoint,
    isSystem: true,
  );

  static final AppListType restaurants = AppListType(
    id: 'sys_restaurants',
    name: 'Restaurants',
    axis1Label: 'Occasion',
    axis2Label: 'Cuisine',
    iconCodePoint: Icons.restaurant_outlined.codePoint,
    isSystem: true,
  );

  static final AppListType entertainment = AppListType(
    id: 'sys_entertainment',
    name: 'Entertainment',
    axis1Label: 'Location',
    axis2Label: 'Activity',
    iconCodePoint: Icons.local_activity_outlined.codePoint,
    isSystem: true,
  );

  static List<AppListType> get systemDefaults => [
    shopping, tasks, movies, restaurants, entertainment
  ];
}