import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isCompact;

  const SectionHeader({
    required this.title,
    this.isCompact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // FIXED: Explicitly sizing the physical header aligns perfectly with the engine
      height: isCompact ? 36.0 : 56.0,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(
          left: AppConstants.padMedium,
          right: AppConstants.padMedium,
          bottom: AppConstants.padSmall
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}