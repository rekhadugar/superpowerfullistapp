import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ListItemCard extends StatelessWidget {
  final String itemName;

  const ListItemCard({required this.itemName, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 80,
      decoration: BoxDecoration(
          color: AppTheme.surface, // Powered by Theme
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border), // Powered by Theme
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              itemName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary, // Powered by Theme
              ),
            ),
            const Text(
              'Hold to drag',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary, // Powered by Theme
              ),
            ),
          ],
        ),
      ),
    );
  }
}