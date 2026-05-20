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
      height: AppConstants.headerHeight,
      width: double.infinity,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(
        // FIX: Matches the exact indent of the AppBar and ListItem titles
        left: AppConstants.horizontalPadding + AppConstants.leadingBlockWidth + AppConstants.interElementGap,
        right: AppConstants.horizontalPadding,
        bottom: AppConstants.headerBottomPadding,
      ),
      color: theme.scaffoldBackgroundColor,
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontSize: AppConstants.headerFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: theme.textTheme.titleLarge?.color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}