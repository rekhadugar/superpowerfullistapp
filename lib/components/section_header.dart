import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20, // CHANGED: Significantly larger than the item name font (18px)
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}