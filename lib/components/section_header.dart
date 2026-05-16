import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final int itemCount;

  const SectionHeader({
    required this.title,
    required this.itemCount,
    super.key,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'groceries': return Colors.orange;
      case 'hardware': return Colors.blueGrey;
      case 'pharmacy': return Colors.redAccent;
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Added 16px of horizontal padding so it aligns exactly with the text inside the card
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: _getCategoryColor(title),
            ),
          ),
          Text(
            '$itemCount',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}