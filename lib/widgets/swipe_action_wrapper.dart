// Location: lib/widgets/swipe_action_wrapper.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class SwipeActionWrapper extends StatefulWidget {
  final Widget child;
  final String itemId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SwipeActionWrapper({
    Key? key,
    required this.child,
    required this.itemId,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<SwipeActionWrapper> createState() => _SwipeActionWrapperState();
}

class _SwipeActionWrapperState extends State<SwipeActionWrapper> with SingleTickerProviderStateMixin {

  // =========================================================================
  // --- PHYSICS CONFIGURATION (User Customized) ---
  // =========================================================================

  // 1. Layout
  final double configMenuWidth = 0.45;          // % of screen for the Edit/Delete menu
  final double configDeleteSlotRatio = 0.30;    // Proportion of menu for Delete (0.40 = 40%)
  final double configEditSlotRatio = 0.70;      // Proportion of menu for Edit (Ensure total is 1.0)

  // 2. Friction & Resistance
  final double configFrictionYield = 0.70;
  final double configFlickVelocity = 400.0;
  final double configFlickMinDistance = 50.0;

  // 3. Animation & Visuals
  final int configSnapDurationMs = 400;
  final double configSwallowSpeed = 2.3;
  final double configContinuousSwallowSpeed = 3.0;

  // =========================================================================

  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  double _rawDragDistance = 0.0;
  double _currentVisualOffset = 0.0;

  // State Tracking
  double _dragStartPosition = 0.0;
  bool _isDeleting = false;

  double get _menuSnapWidth => MediaQuery.of(context).size.width * configMenuWidth;

  double get _activeSwallowSpeed => (_dragStartPosition.abs() < 1.0)
      ? configContinuousSwallowSpeed
      : configSwallowSpeed;

  bool get _isSwallowComplete {
    final double exposedWidth = _currentVisualOffset.abs();
    if (exposedWidth <= _menuSnapWidth) return false;

    // Mathematically driven by the new configuration ratio
    final double deleteSlotWidth = _menuSnapWidth * configDeleteSlotRatio;
    final double extraVisualDrag = exposedWidth - _menuSnapWidth;
    final double deleteWidth = deleteSlotWidth + (extraVisualDrag * _activeSwallowSpeed);

    return deleteWidth >= exposedWidth;
  }

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: configSnapDurationMs),
    );
    _snapController.addListener(() {
      setState(() {
        _currentVisualOffset = _snapAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_snapController.isAnimating) {
      _snapController.stop();
    }
    _dragStartPosition = _currentVisualOffset;
    _rawDragDistance = _currentVisualOffset;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDeleting) return;

    setState(() {
      _rawDragDistance += details.delta.dx;
      if (_rawDragDistance > 0) _rawDragDistance = 0;

      if (_rawDragDistance.abs() <= _menuSnapWidth) {
        _currentVisualOffset = _rawDragDistance;
      } else {
        final overDrag = _rawDragDistance.abs() - _menuSnapWidth;
        _currentVisualOffset = -(_menuSnapWidth + (overDrag * configFrictionYield));
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isDeleting) return;

    final double velocity = details.primaryVelocity ?? 0.0;

    final double distanceDragged = (_rawDragDistance - _dragStartPosition).abs();

    final bool isFlingingLeft = velocity < -configFlickVelocity && distanceDragged >= configFlickMinDistance;
    final bool isFlingingRight = velocity > configFlickVelocity && distanceDragged >= configFlickMinDistance;

    final bool crossedHalfway = _currentVisualOffset.abs() > (_menuSnapWidth * 0.5);

    if (_isSwallowComplete) {
      setState(() {
        _isDeleting = true;
      });
      widget.onDelete();
      _snapTo(0.0);
      return;
    }

    if (isFlingingRight) {
      _snapTo(0.0);
    } else if (isFlingingLeft || crossedHalfway) {
      _snapTo(-_menuSnapWidth);
    } else {
      _snapTo(0.0);
    }
  }

  void _snapTo(double targetOffset) {
    _snapAnimation = Tween<double>(
      begin: _currentVisualOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutQuart,
    ));
    _snapController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final double exposedWidth = _currentVisualOffset.abs();

    // Driven by user configuration
    final double deleteSlotWidth = _menuSnapWidth * configDeleteSlotRatio;
    final double editSlotWidth = _menuSnapWidth * configEditSlotRatio;

    double deleteWidth = 0.0;
    if (_isDeleting) {
      deleteWidth = exposedWidth;
    } else if (exposedWidth <= _menuSnapWidth) {
      // Proportional sharing matches the configuration perfectly
      deleteWidth = exposedWidth * configDeleteSlotRatio;
    } else {
      final double extraVisualDrag = exposedWidth - _menuSnapWidth;
      deleteWidth = deleteSlotWidth + (extraVisualDrag * _activeSwallowSpeed);
    }
    deleteWidth = deleteWidth.clamp(0.0, exposedWidth);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppConstants.cardMargin),
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: exposedWidth,
                  child: Stack(
                    children: [
                      // BLUE EDIT LAYER
                      GestureDetector(
                        onTap: () {
                          if (!_isDeleting) {
                            widget.onEdit();
                            _snapTo(0.0);
                          }
                        },
                        onHorizontalDragStart: _onDragStart,
                        onHorizontalDragUpdate: _onDragUpdate,
                        onHorizontalDragEnd: _onDragEnd,
                        behavior: HitTestBehavior.opaque,
                        child: ClipRect(
                          child: Container(
                            width: exposedWidth,
                            color: AppColors.primaryAction,
                            child: Stack(
                              children: [
                                Positioned(
                                  // Icon perfectly anchored in its newly configured slot width
                                  right: deleteSlotWidth + (editSlotWidth / 2) - 11.0,
                                  top: 0,
                                  bottom: 0,
                                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 22.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // RED DELETE LAYER
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: deleteWidth,
                        child: GestureDetector(
                          onTap: () {
                            if (!_isDeleting) {
                              widget.onDelete();
                              _snapTo(0.0);
                            }
                          },
                          onHorizontalDragStart: _onDragStart,
                          onHorizontalDragUpdate: _onDragUpdate,
                          onHorizontalDragEnd: _onDragEnd,
                          behavior: HitTestBehavior.opaque,
                          child: ClipRect(
                            child: Container(
                              color: AppColors.destructiveAction,
                              child: Stack(
                                children: [
                                  Positioned(
                                    // Icon perfectly anchored in its newly configured slot width
                                    right: (deleteSlotWidth / 2) - 12.0,
                                    top: 0,
                                    bottom: 0,
                                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 24.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        Transform.translate(
          offset: Offset(_currentVisualOffset, 0),
          child: GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}