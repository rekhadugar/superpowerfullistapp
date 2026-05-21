import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';
import '../engine/sort_mode_engine.dart';

class ListItemCard extends StatefulWidget {
  final String itemId;
  final String title;
  final int nWrap;
  final int nTagRows;
  final List<String> attributeRows;
  final String type;
  final String category;
  final SortMode sortMode;
  final int quantity;
  final bool isHighlighted;
  final bool isEditMode;
  final bool isSelected;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ListItemCard({
    Key? key,
    required this.itemId,
    required this.title,
    this.nWrap = 0,
    this.nTagRows = 0,
    this.attributeRows = const [],
    required this.type,
    required this.category,
    required this.sortMode,
    required this.quantity,
    this.isHighlighted = false,
    this.isEditMode = false,
    this.isSelected = false,
    this.isDragging = false,
    required this.onTap,
    required this.onLongPress,
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

    if (widget.isHighlighted) {
      _triggerFlash();
    }
  }

  @override
  void didUpdateWidget(ListItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _triggerFlash();
    }
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

  // NEW: Added 'ListProvider provider' to the signature
  Widget _buildCardContent(ThemeData theme, double computedHeight, String contextBadgeText, IconData contextIcon, ListProvider provider, {bool isFeedback = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
      decoration: BoxDecoration(
        color: isFeedback ? theme.cardColor : Colors.transparent,
        borderRadius: isFeedback ? BorderRadius.circular(12.0) : null,
        boxShadow: isFeedback ? [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 8))] : null,
        border: isFeedback ? Border.all(color: AppColors.primaryAction.withOpacity(0.3), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: AppConstants.baseCardHeight + (widget.nWrap * AppConstants.nameWrapHeightStep) - AppConstants.borderWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: AppConstants.leadingBlockWidth,
                  height: AppConstants.attributeRowHeight,
                  alignment: Alignment.center,
                  child: widget.isEditMode
                      ? (isFeedback
                      ? Icon(Icons.drag_handle_rounded, color: widget.isSelected ? AppColors.primaryAction : theme.dividerColor)
                      : Draggable<String>(
                    data: widget.itemId,
                    // NEW: Safely uses the captured provider reference, bypassing the unmounted widget context!
                    onDragStarted: () => provider.setDraggingItem(widget.itemId),
                    onDragEnd: (_) => provider.setDraggingItem(null),
                    onDraggableCanceled: (_, __) => provider.setDraggingItem(null),
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: _buildCardContent(theme, computedHeight, contextBadgeText, contextIcon, provider, isFeedback: true),
                      ),
                    ),
                    childWhenDragging: SizedBox(width: AppConstants.leadingBlockWidth, height: AppConstants.attributeRowHeight),
                    child: Icon(Icons.drag_handle_rounded, color: widget.isSelected ? AppColors.primaryAction : theme.dividerColor),
                  ))
                      : Icon(Icons.check_box_outline_blank, color: widget.isSelected ? AppColors.primaryAction : theme.dividerColor),
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
                    '${widget.quantity}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: AppConstants.titleFontSize,
                      height: AppConstants.titleLineHeight,
                      color: widget.isEditMode ? theme.dividerColor.withOpacity(0.3) : null,
                    ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // NEW: Capture the provider reference while the widget is still safely mounted
    final provider = context.read<ListProvider>();

    final double computedHeight = AppConstants.baseCardHeight +
        (widget.nWrap * AppConstants.nameWrapHeightStep) +
        AppConstants.attributeRowHeight +
        (widget.nTagRows * AppConstants.attributeRowHeight);

    final String contextBadgeText = widget.sortMode == SortMode.categories ? widget.type : widget.category;
    final IconData contextIcon = widget.sortMode == SortMode.categories ? Icons.storefront : Icons.category_outlined;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          Color? backgroundColor = widget.isSelected
              ? AppColors.primaryAction.withOpacity(0.08)
              : theme.cardColor;
          if (_flashController.isAnimating) {
            backgroundColor = _colorAnimation.value;
          }

          return Container(
            height: computedHeight,
            margin: const EdgeInsets.only(bottom: AppConstants.cardMargin),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor, width: AppConstants.borderWidth)),
            ),
            child: Opacity(
              opacity: widget.isDragging ? 0.0 : 1.0,
              // NEW: Pass the captured provider down to the content builder
              child: _buildCardContent(theme, computedHeight, contextBadgeText, contextIcon, provider),
            ),
          );
        },
      ),
    );
  }
}