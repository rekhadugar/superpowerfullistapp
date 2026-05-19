// Location: lib/widgets/section_header.dart

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Strictly enforced 44px height for the math engine remains untouched
      height: AppConstants.headerHeight,
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: AppConstants.horizontalPadding + AppConstants.leadingBlockWidth + AppConstants.interElementGap,
        right: AppConstants.horizontalPadding,
      ),
      // Solid background is required to prevent visual bleed during sticky scroll
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0), // Snaps text to the bottom baseline
        child: Text(
          title, // Removed .toUpperCase() to match standard item name casing, or you can keep it if preferred
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, // Matches item name size (16px) but forces bold
            color: theme.textTheme.titleMedium?.color, // Solid color to match item titles
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}