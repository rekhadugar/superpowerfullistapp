// Location: lib/widgets/list_item_card.dart

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';
import '../engine/sort_mode_engine.dart'; // Required for SortMode enum

class ListItemCard extends StatelessWidget {
  final String title;
  final int nWrap;
  final int nTagRows;
  final List<String> attributeRows;
  final String type;
  final String category;
  final SortMode sortMode;
  final VoidCallback onTap;

  const ListItemCard({
    Key? key,
    required this.title,
    this.nWrap = 0,
    this.nTagRows = 0,
    this.attributeRows = const [],
    required this.type,
    required this.category,
    required this.sortMode,
    required this.onTap,
  }) : super(key: key);

  Widget _buildBadge(ThemeData theme, String text, IconData icon) {
    return Container(
      height: AppConstants.badgeHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.badgeHorizontalPadding),
      decoration: BoxDecoration(
        color: theme.dividerColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.badgeBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppConstants.badgeIconSize,
            color: theme.textTheme.labelSmall?.color,
          ),
          const SizedBox(width: AppConstants.badgeIconGap),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: AppConstants.badgeFontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Deterministic height calculation perfectly matching the StickyHeaderEngine
    final double computedHeight = AppConstants.baseCardHeight +
        (nWrap * AppConstants.nameWrapHeightStep) +
        AppConstants.attributeRowHeight + // The fixed Context Badge row
        (nTagRows * AppConstants.attributeRowHeight); // The dynamically measured tag rows

    // Determine context badge based on the active SortMode
    final String contextBadgeText = sortMode == SortMode.categories ? type : category;
    final IconData contextIcon = sortMode == SortMode.categories ? Icons.storefront : Icons.category_outlined;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: computedHeight,
        margin: const EdgeInsets.only(bottom: AppConstants.cardMargin),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(bottom: BorderSide(color: theme.dividerColor, width: AppConstants.borderWidth)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Base Height Title Row
            Container(
              height: AppConstants.baseCardHeight + (nWrap * AppConstants.nameWrapHeightStep) - AppConstants.borderWidth,
              padding: const EdgeInsets.only(top: AppConstants.cardTopPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppConstants.leadingBlockWidth,
                    height: AppConstants.attributeRowHeight, // 25px baseline
                    alignment: Alignment.center,
                    child: Icon(Icons.check_box_outline_blank, color: theme.dividerColor),
                  ),
                  const SizedBox(width: AppConstants.interElementGap),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: AppConstants.maxTitleLines,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: AppConstants.titleFontSize,
                        height: AppConstants.titleLineHeight,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.interElementGap),
                  Container(
                    width: AppConstants.trailingBlockWidth,
                    height: AppConstants.attributeRowHeight,
                    alignment: Alignment.center,
                    child: Text(
                        '1',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall
                    ),
                  ),
                ],
              ),
            ),

            // 1. Fixed Context Badge Row (Type or Category depending on SortMode)
            // 1. Fixed Context Badge Row (Type or Category depending on SortMode)
            SizedBox(
              height: AppConstants.attributeRowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Top align to push the 6px remainder to the bottom
                children: [
                  const SizedBox(width: AppConstants.leadingBlockWidth + AppConstants.interElementGap),
                  _buildBadge(theme, contextBadgeText, contextIcon),
                ],
              ),
            ),

            // 2. Dynamic Tag Rows (Wrapped and mathematically constrained)
            if (attributeRows.isNotEmpty && nTagRows > 0)
              Container(
                width: double.infinity,
                height: nTagRows * AppConstants.attributeRowHeight,
                padding: const EdgeInsets.only(
                  left: AppConstants.leadingBlockWidth + AppConstants.interElementGap,
                  top: 0.0, // Top align to push the 6px remainder to the bottom
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: attributeRows.map((attr) => _buildBadge(theme, attr, Icons.sell_outlined)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}