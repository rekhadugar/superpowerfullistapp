import 'package:flutter/material.dart';

enum ListType {
  shopping,
  tasks,
  movies;

  String get displayName {
    switch (this) {
      case ListType.shopping:
        return 'Shopping';
      case ListType.tasks:
        return 'Tasks & ToDo';
      case ListType.movies:
        return 'Movies and TV';
    }
  }

  IconData get icon {
    switch (this) {
      case ListType.shopping:
        return Icons.shopping_cart_outlined;
      case ListType.tasks:
        return Icons.check_box_outlined;
      case ListType.movies:
        return Icons.movie_creation_outlined;
    }
  }
}