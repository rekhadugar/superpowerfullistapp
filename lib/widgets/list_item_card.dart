import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // NEW
import '../providers/macro_list_provider.dart'; // NEW
import '../providers/settings_provider.dart'; // NEW
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

  final bool isBatchModeActive;
  final bool isBatchSelected;
  final bool isFluidEditing;

  final VoidCallback onTap;
  final VoidCallback onCheck;
  final VoidCallback onToggleSelection;

  const ListItemCard({
    super.key,
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
  });

  @override
  State<ListItemCard> createState() => _ListItemCardState();
}

class _ListItemCardState extends State<ListItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _colorAnimation;

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
    _colorAnimation = ColorTween(begin: theme.cardColor, end: AppColors.primaryAction.withValues(alpha: 0.15))
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
    if (_wasLongPressed) return;

    if (widget.isBatchModeActive) {
      widget.onToggleSelection();
    } else {
      widget.onTap();
    }
  }

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

      widget.onToggleSelection();
    }
  }

  void _onPointerCancel(PointerEvent event) {
    _grabTimer?.cancel();
    _wasLongPressed = true;
    if (mounted) setState(() => _isGrabbed = false);
    _startPosition = null;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _wasLongPressed = false;
    });
  }

  // FIXED: Badge generation now consumes the FluidGeometry lens directly
  Widget _buildBadge(ThemeData theme, String text, IconData icon, FluidGeometry geometry) {
    return Container(
      height: geometry.badgeHeight,
      padding: EdgeInsets.symmetric(horizontal: geometry.badgeHorizontalPadding),
      decoration: BoxDecoration(color: theme.dividerColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4.0)), // Static radius for badges
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: geometry.badgeIconSize, color: theme.textTheme.labelSmall?.color),
          SizedBox(width: geometry.badgeIconGap),
          Flexible( // Prevents massive text scaling from breaking the row
            child: Text(text, style: theme.textTheme.labelSmall?.copyWith(fontSize: AppConstants.badgeFontSize, fontWeight: FontWeight.w600, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    // FIXED: Instantiate the active geometry constraints
    final geometry = FluidGeometry(textScale);

    // --- ALIAS MAPPING ENGINE ---
    final macroProvider = context.watch<MacroListProvider>();
    final settings = context.watch<SettingsProvider>();
    final typeId = macroProvider.activeList?.typeId ?? 'sys_shopping';
    final appType = settings.getTypeById(typeId);

    // If sorting by Categories (Axis 2), display the Store (Axis 1) badge for context
    final bool showAxis1 = widget.sortMode == SortMode.categories;
    final String contextBadgeText = showAxis1 ? widget.type : widget.category;

    // Dynamically assign the list's main icon to Axis 1, and a generic folder to Axis 2
    final IconData contextIcon = showAxis1
        ? IconData(appType.iconCodePoint, fontFamily: 'MaterialIcons')
        : Icons.folder_outlined;

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
              Color? backgroundColor = (widget.isBatchSelected || widget.isFluidEditing)
                  ? AppColors.primaryAction.withValues(alpha: 0.08)
                  : theme.cardColor;

              if (_flashController.isAnimating) backgroundColor = _colorAnimation.value;

              return Container(
                padding: EdgeInsets.symmetric(horizontal: geometry.horizontalPadding),
                margin: widget.isFeedback ? EdgeInsets.zero : const EdgeInsets.only(bottom: AppConstants.cardMargin),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: widget.isFeedback ? BorderRadius.circular(12.0) : null,
                  border: widget.isFeedback ? Border.all(color: AppColors.primaryAction.withValues(alpha: 0.3), width: 1.5) : Border(bottom: BorderSide(color: theme.dividerColor, width: AppConstants.borderWidth)),
                ),
                child: Opacity(opacity: widget.isDragging ? 0.0 : 1.0, child: child),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: widget.isFeedback ? MainAxisSize.min : MainAxisSize.max,
              children: [
                SizedBox(
                  height: (geometry.baseCardHeight + (widget.nWrap * geometry.nameWrapHeightStep)) - AppConstants.borderWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => widget.isBatchModeActive ? widget.onToggleSelection() : widget.onCheck(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: geometry.leadingBlockWidth,
                          height: geometry.baseCardHeight,
                          alignment: Alignment.center,
                          child: widget.isBatchModeActive
                          // FIXED: Injected geometry.iconSize
                              ? Icon(widget.isBatchSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank, size: geometry.iconSize, color: widget.isBatchSelected ? AppColors.primaryAction : theme.dividerColor)
                              : Icon(Icons.check_box_outline_blank, size: geometry.iconSize, color: theme.dividerColor),
                        ),
                      ),
                      SizedBox(width: geometry.interElementGap),
                      Expanded(
                        child: Text(
                          widget.quantity > 0 ? '${widget.title} - ${widget.quantity} ${widget.unit}' : widget.title,
                          maxLines: AppConstants.maxTitleLines, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: AppConstants.titleFontSize,
                            height: AppConstants.titleLineHeight,
                            // FIXED: Bumped to w600 (Semi-bold) to pop against the regular badges
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                SizedBox(
                  height: geometry.attributeRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: geometry.leadingBlockWidth + geometry.interElementGap),
                      _buildBadge(theme, contextBadgeText, contextIcon, geometry),
                    ],
                  ),
                ),
                if (widget.attributeRows.isNotEmpty && widget.nTagRows > 0)
                  Container(
                    width: double.infinity,
                    height: widget.nTagRows * geometry.attributeRowHeight,
                    padding: EdgeInsets.only(left: geometry.leadingBlockWidth + geometry.interElementGap, top: 0.0),
                    child: Wrap(spacing: 8.0, runSpacing: 6.0, children: widget.attributeRows.map((attr) => _buildBadge(theme, attr, Icons.sell_outlined, geometry)).toList()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}