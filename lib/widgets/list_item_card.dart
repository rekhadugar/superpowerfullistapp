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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Base Height Title Row (Accounts for Name Wraps and 1px border)
            Container(
              height: AppConstants.baseCardHeight + (nWrap * AppConstants.nameWrapHeightStep) - 1.0,
              padding: const EdgeInsets.only(top: 18.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppConstants.leadingBlockWidth,
                    height: 20.0,
                    alignment: Alignment.center,
                    child: Icon(Icons.check_box_outline_blank, color: theme.dividerColor),
                  ),
                  const SizedBox(width: AppConstants.interElementGap),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16.0,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.interElementGap),
                  Container(
                    width: AppConstants.trailingBlockWidth,
                    height: 20.0,
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
            // Dynamic Attribute Rows mathematically constrained to 20px
            if (attributeRows.isNotEmpty)
              ...attributeRows.map((attr) => SizedBox(
                height: AppConstants.attributeRowHeight, // The unbreakable 20px math constraint
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: AppConstants.leadingBlockWidth + AppConstants.interElementGap),

                    // Maximized Pill Badge (Exactly 20.0px tall)
                    Container(
                      height: 20.0, // Expanded from 18.0 to the absolute maximum safe limit
                      padding: const EdgeInsets.symmetric(horizontal: 10.0), // Slightly wider padding for larger text
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10.0), // Exactly half of 20.0px for a perfect circle edge
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                              Icons.sell_outlined,
                              size: 12.0, // Increased from 10.0
                              color: theme.textTheme.labelSmall?.color
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            attr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12.0, // Increased from 10.0 for much better legibility
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              height: 1.1, // Tight line height prevents vertical clipping
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