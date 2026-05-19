// Location: lib/widgets/list_item_card.dart

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

class ListItemCard extends StatelessWidget {
  final String title;
  final int nWrap; // Inject the wrap factor
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

    // Deterministic height calculation: Base + Wraps + Attribute Rows
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
          border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start, // Shifted to start for predictable rendering
          children: [
            // Base Height Title Row (Accounts for Name Wraps and 1px border)
            Container(
              height: AppConstants.baseCardHeight + (nWrap * AppConstants.nameWrapHeightStep) - 1.0,
              padding: const EdgeInsets.only(top: 18.0), // Strict top padding to center the first 20px line
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Anchor strictly to first line
                children: [
                  // 1. Fixed Interactive Leading Block
                  Container(
                    width: AppConstants.leadingBlockWidth,
                    height: 20.0, // Match exact 20px first line height
                    alignment: Alignment.center,
                    child: Icon(Icons.check_box_outline_blank, color: theme.dividerColor),
                  ),
                  const SizedBox(width: AppConstants.interElementGap),

                  // 2. Flexible Text Title Area
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 6, // Expanded to support up to 6 lines per spec
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16.0,
                        height: 1.25, // 16 * 1.25 = exactly 20px per line footprint
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.interElementGap),

                  // 3. Fixed Trailing Action Block
                  Container(
                    width: AppConstants.trailingBlockWidth,
                    height: 20.0, // Match exact 20px first line height
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
            // Dynamic Attribute Rows mathematically constrained
            if (attributeRows.isNotEmpty)
              ...attributeRows.map((attr) => SizedBox(
                height: AppConstants.attributeRowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Spacer to perfectly align the icon with the title text above it
                    const SizedBox(width: AppConstants.leadingBlockWidth + AppConstants.interElementGap),
                    Icon(
                        Icons.tag,
                        size: AppConstants.attributeIconSize,
                        color: theme.iconTheme.color
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        attr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12.0,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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