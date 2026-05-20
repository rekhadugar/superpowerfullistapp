// Location: lib/widgets/list_item_card.dart

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

class ListItemCard extends StatelessWidget {
  final String title;
  final int nWrap;
  final List<String> attributeRows;
  final VoidCallback onTap;

  const ListItemCard({
    Key? key,
    required this.title,
    this.nWrap = 0,
    this.attributeRows = const [],
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Deterministic height calculation
    final double computedHeight = AppConstants.baseCardHeight +
        (nWrap * AppConstants.nameWrapHeightStep) +
        (attributeRows.length * AppConstants.attributeRowHeight);

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
                    height: AppConstants.attributeRowHeight,
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
            // Dynamic Attribute Rows
            if (attributeRows.isNotEmpty)
              ...attributeRows.map((attr) => SizedBox(
                height: AppConstants.attributeRowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Vertically centers the 19px badge inside the 25px row
                  children: [
                    const SizedBox(width: AppConstants.leadingBlockWidth + AppConstants.interElementGap),
                    Container(
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
                              Icons.sell_outlined,
                              size: AppConstants.badgeIconSize,
                              color: theme.textTheme.labelSmall?.color
                          ),
                          const SizedBox(width: AppConstants.badgeIconGap),
                          Text(
                            attr,
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
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}