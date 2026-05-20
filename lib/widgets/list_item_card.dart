// Location: lib/widgets/list_item_card.dart

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import '../engine/sort_mode_engine.dart';

class ListItemCard extends StatefulWidget {
  final String title;
  final int nWrap;
  final int nTagRows;
  final List<String> attributeRows;
  final String type;
  final String category;
  final SortMode sortMode;
  final bool isHighlighted;
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
    this.isHighlighted = false,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ListItemCard> createState() => _ListItemCardState();
}

class _ListItemCardState extends State<ListItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);

    // Tween from normal card color to a translucent primary highlight
    _colorAnimation = ColorTween(
      begin: theme.cardColor,
      end: AppColors.primaryAction.withOpacity(0.15),
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    ));

    // If the card is built while highlighted (e.g., scrolled into view), flash it
    if (widget.isHighlighted) {
      _triggerFlash();
    }
  }

  @override
  void didUpdateWidget(ListItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when the property changes from false to true
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _triggerFlash();
    }
  }

  void _triggerFlash() {
    // Stagger the flash: 800ms scroll + 100ms pause = 900ms delay
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _flashController.forward().then((_) {
          if (mounted) _flashController.reverse();
        });
      }
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

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
        (widget.nWrap * AppConstants.nameWrapHeightStep) +
        AppConstants.attributeRowHeight +
        (widget.nTagRows * AppConstants.attributeRowHeight);

    final String contextBadgeText = widget.sortMode == SortMode.categories ? widget.type : widget.category;
    final IconData contextIcon = widget.sortMode == SortMode.categories ? Icons.storefront : Icons.category_outlined;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            height: computedHeight,
            margin: const EdgeInsets.only(bottom: AppConstants.cardMargin),
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            decoration: BoxDecoration(
              color: _colorAnimation.value, // Driven by the animation tween
              border: Border(bottom: BorderSide(color: theme.dividerColor, width: AppConstants.borderWidth)),
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: AppConstants.baseCardHeight + (widget.nWrap * AppConstants.nameWrapHeightStep) - AppConstants.borderWidth,
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
                      widget.title,
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

            SizedBox(
              height: AppConstants.attributeRowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: AppConstants.leadingBlockWidth + AppConstants.interElementGap),
                  _buildBadge(theme, contextBadgeText, contextIcon),
                ],
              ),
            ),

            if (widget.attributeRows.isNotEmpty && widget.nTagRows > 0)
              Container(
                width: double.infinity,
                height: widget.nTagRows * AppConstants.attributeRowHeight,
                padding: const EdgeInsets.only(
                  left: AppConstants.leadingBlockWidth + AppConstants.interElementGap,
                  top: 0.0,
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: widget.attributeRows.map((attr) => _buildBadge(theme, attr, Icons.sell_outlined)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}