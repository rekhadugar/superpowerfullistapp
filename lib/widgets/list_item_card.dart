import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // PRODUCTION REFACTOR: STRICTLY SEPARATED CONCERNS
  final bool isBatchModeActive;
  final bool isBatchSelected;
  final bool isFluidEditing;

  final VoidCallback onTap;
  final VoidCallback onCheck;
  final VoidCallback onToggleSelection;

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
    this.isBatchModeActive = false,
    this.isBatchSelected = false,
    this.isFluidEditing = false,
    required this.onTap,
    required this.onCheck,
    required this.onToggleSelection,
  }) : super(key: key);

  @override
  State<ListItemCard> createState() => _ListItemCardState();
}

class _ListItemCardState extends State<ListItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _colorAnimation;

  // --- PASSIVE DUAL-INTENT STATE ---
  Offset? _startPosition;
  bool _isGrabbed = false;
  bool _hasMoved = false;
  Timer? _grabTimer;
  bool _wasLongPressed = false;
  DateTime? _touchStartTime;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    _colorAnimation = ColorTween(begin: theme.cardColor, end: AppColors.primaryAction.withOpacity(0.15))
        .animate(CurvedAnimation(parent: _flashController, curve: Curves.easeInOut));
    if (widget.isHighlighted) _triggerFlash();
  }

  @override
  void didUpdateWidget(ListItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) _triggerFlash();
  }

  void _triggerFlash() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _flashController.forward().then((_) { if (mounted) _flashController.reverse(); });
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    _grabTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (_wasLongPressed) return; // Absorb rogue taps from the gesture arena

    if (widget.isBatchModeActive) {
      widget.onToggleSelection();
    } else {
      widget.onTap();
    }
  }

  // --- PASSIVE POINTER TRACKING ---
  void _onPointerDown(PointerDownEvent event) {
    if (widget.isBatchModeActive) return;

    _startPosition = event.position;
    _hasMoved = false;
    _touchStartTime = DateTime.now();

    _grabTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_hasMoved && mounted) {
        HapticFeedback.selectionClick();
        setState(() => _isGrabbed = true);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (widget.isBatchModeActive || _startPosition == null) return;

    if ((event.position - _startPosition!).distance > 10.0) {
      _hasMoved = true;
      _grabTimer?.cancel();
      if (_isGrabbed && mounted) setState(() => _isGrabbed = false);
    }
  }

  void _onPointerUp(PointerEvent event) {
    _grabTimer?.cancel();
    if (mounted) setState(() => _isGrabbed = false);

    if (widget.isBatchModeActive || _touchStartTime == null) return;

    final holdMs = DateTime.now().difference(_touchStartTime!).inMilliseconds;
    _startPosition = null;

    if (!_hasMoved && holdMs >= 300) {
      _wasLongPressed = true;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _wasLongPressed = false;
      });

      // INTENT A: Held and released safely. Trigger selection!
      widget.onToggleSelection();
    }
  }

  void _onPointerCancel(PointerEvent event) {
    // INTENT B: ReorderableListView stole the pointer to start dragging!
    // Cancel everything and let the drop-in-place fallback handle it.
    _grabTimer?.cancel();
    _wasLongPressed = true;
    if (mounted) setState(() => _isGrabbed = false);
    _startPosition = null;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _wasLongPressed = false;
    });
  }

  Widget _buildBadge(ThemeData theme, String text, IconData icon, double textScale) {
    return Container(
      height: AppConstants.badgeHeight * textScale,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.badgeHorizontalPadding),
      decoration: BoxDecoration(color: theme.dividerColor.withOpacity(0.3), borderRadius: BorderRadius.circular(AppConstants.badgeBorderRadius)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppConstants.badgeIconSize, color: theme.textTheme.labelSmall?.color),
          const SizedBox(width: AppConstants.badgeIconGap),
          Text(text, style: theme.textTheme.labelSmall?.copyWith(fontSize: AppConstants.badgeFontSize, fontWeight: FontWeight.w600, height: 1.1), maxLines: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final String contextBadgeText = widget.sortMode == SortMode.categories ? widget.type : widget.category;
    final IconData contextIcon = widget.sortMode == SortMode.categories ? Icons.storefront : Icons.category_outlined;

    return AnimatedScale(
      scale: _isGrabbed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              // COMBINED HIGHLIGHT LOGIC: Highlights if part of a batch OR if currently fluid editing
              Color? backgroundColor = (widget.isBatchSelected || widget.isFluidEditing)
                  ? AppColors.primaryAction.withOpacity(0.08)
                  : theme.cardColor;

              if (_flashController.isAnimating) backgroundColor = _colorAnimation.value;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
                margin: widget.isFeedback ? EdgeInsets.zero : const EdgeInsets.only(bottom: AppConstants.cardMargin),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: widget.isFeedback ? BorderRadius.circular(12.0) : null,
                  border: widget.isFeedback ? Border.all(color: AppColors.primaryAction.withOpacity(0.3), width: 1.5) : Border(bottom: BorderSide(color: theme.dividerColor, width: AppConstants.borderWidth)),
                ),
                child: Opacity(opacity: widget.isDragging ? 0.0 : 1.0, child: child),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: widget.isFeedback ? MainAxisSize.min : MainAxisSize.max,
              children: [
                SizedBox(
                  height: ((AppConstants.baseCardHeight + (widget.nWrap * AppConstants.nameWrapHeightStep)) * textScale) - AppConstants.borderWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => widget.isBatchModeActive ? widget.onToggleSelection() : widget.onCheck(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: AppConstants.leadingBlockWidth,
                          height: AppConstants.baseCardHeight * textScale,
                          alignment: Alignment.center,
                          child: widget.isBatchModeActive
                              ? Icon(widget.isBatchSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank, color: widget.isBatchSelected ? AppColors.primaryAction : theme.dividerColor)
                              : Icon(Icons.check_box_outline_blank, color: theme.dividerColor),
                        ),
                      ),
                      const SizedBox(width: AppConstants.interElementGap),
                      Expanded(
                        child: Text(
                          widget.quantity > 0 ? '${widget.title} - ${widget.quantity} ${widget.unit}' : widget.title,
                          maxLines: AppConstants.maxTitleLines, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: AppConstants.titleFontSize, height: AppConstants.titleLineHeight),
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
                    padding: const EdgeInsets.only(left: AppConstants.leadingBlockWidth + AppConstants.interElementGap, top: 0.0),
                    child: Wrap(spacing: 8.0, runSpacing: 6.0, children: widget.attributeRows.map((attr) => _buildBadge(theme, attr, Icons.sell_outlined, textScale)).toList()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}