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
  final int quantity;
  final String unit;
  final bool isHighlighted;
  final bool isDragging;
  final bool isFeedback;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCheck;

  const ListItemCard({
    Key? key,
    required this.title,
    this.nWrap = 0,
    this.nTagRows = 0,
    this.attributeRows = const [],
    required this.type,
    required this.category,
    required this.sortMode,
    required this.quantity,
    required this.unit,
    this.isHighlighted = false,
    this.isDragging = false,
    this.isFeedback = false,
    this.isEditMode = false,
    this.isSelected = false,
    required this.onTap,
    required this.onCheck,
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

    _colorAnimation = ColorTween(
      begin: theme.cardColor,
      end: AppColors.primaryAction.withOpacity(0.15),
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    ));

    if (widget.isHighlighted) _triggerFlash();
  }

  @override
  void didUpdateWidget(ListItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) _triggerFlash();
  }

  void _triggerFlash() {
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

  // Modified to take textScale
  Widget _buildBadge(ThemeData theme, String text, IconData icon, double textScale) {
    return Container(
      height: AppConstants.badgeHeight * textScale,
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
    final textScale = MediaQuery.textScalerOf(context).scale(1.0); // Fetch Scale

    final String contextBadgeText = widget.sortMode == SortMode.categories ? widget.type : widget.category;
    final IconData contextIcon = widget.sortMode == SortMode.categories ? Icons.storefront : Icons.category_outlined;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          Color? backgroundColor = widget.isSelected
              ? AppColors.primaryAction.withOpacity(0.08)
              : theme.cardColor;

          if (_flashController.isAnimating) backgroundColor = _colorAnimation.value;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            margin: widget.isFeedback ? EdgeInsets.zero : const EdgeInsets.only(bottom: AppConstants.cardMargin),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: widget.isFeedback ? BorderRadius.circular(12.0) : null,
              boxShadow: widget.isFeedback ? [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 8))] : null,
              border: widget.isFeedback
                  ? Border.all(color: AppColors.primaryAction.withOpacity(0.3), width: 1.5)
                  : Border(bottom: BorderSide(color: theme.dividerColor, width: AppConstants.borderWidth)),
            ),
            child: Opacity(
              opacity: widget.isDragging ? 0.0 : 1.0,
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: widget.isFeedback ? MainAxisSize.min : MainAxisSize.max,
          children: [
            SizedBox(
              height: ((AppConstants.baseCardHeight + (widget.nWrap * AppConstants.nameWrapHeightStep)) * textScale) - AppConstants.borderWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.isEditMode) {
                        widget.onTap();
                      } else {
                        widget.onCheck();
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: AppConstants.leadingBlockWidth,
                      height: AppConstants.baseCardHeight * textScale,
                      alignment: Alignment.center,
                      child: widget.isEditMode
                          ? Icon(
                        widget.isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
                        color: widget.isSelected ? AppColors.primaryAction : theme.dividerColor,
                      )
                          : Icon(Icons.check_box_outline_blank, color: theme.dividerColor),
                    ),
                  ),
                  const SizedBox(width: AppConstants.interElementGap),
                  Expanded(
                    child: Text(
                      widget.quantity > 0
                          ? '${widget.title} - ${widget.quantity} ${widget.unit}'
                          : widget.title,
                      maxLines: AppConstants.maxTitleLines,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: AppConstants.titleFontSize,
                        height: AppConstants.titleLineHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: AppConstants.attributeRowHeight * textScale,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: AppConstants.leadingBlockWidth + AppConstants.interElementGap),
                  _buildBadge(theme, contextBadgeText, contextIcon, textScale),
                ],
              ),
            ),

            if (widget.attributeRows.isNotEmpty && widget.nTagRows > 0)
              Container(
                width: double.infinity,
                height: (widget.nTagRows * AppConstants.attributeRowHeight) * textScale,
                padding: const EdgeInsets.only(
                  left: AppConstants.leadingBlockWidth + AppConstants.interElementGap,
                  top: 0.0,
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 6.0,
                  children: widget.attributeRows.map((attr) => _buildBadge(theme, attr, Icons.sell_outlined, textScale)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}