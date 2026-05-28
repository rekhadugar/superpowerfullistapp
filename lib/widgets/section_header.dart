// Location: lib/widgets/section_header.dart

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

// Location: lib/widgets/section_header.dart

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    // Tap into the Fluid Geometry Lens
    final geometry = FluidGeometry(textScale);

    return Container(
      height: geometry.headerHeight,
      width: double.infinity,
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.only(
        left: geometry.horizontalPadding + geometry.leadingBlockWidth + geometry.interElementGap,
        right: geometry.horizontalPadding,
        bottom: AppConstants.headerBottomPadding, // Remains static to anchor the text cleanly
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