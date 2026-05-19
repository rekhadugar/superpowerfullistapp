// Location: lib/widgets/swipe_action_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class SwipeActionWrapper extends StatefulWidget {
  final Widget child;
  final String itemId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool requireConfirm; // NEW: Exposes the tap-to-confirm toggle to parent settings

  const SwipeActionWrapper({
    Key? key,
    required this.child,
    required this.itemId,
    required this.onEdit,
    required this.onDelete,
    this.requireConfirm = true, // Defaults to true for safety
  }) : super(key: key);

  @override
  State<SwipeActionWrapper> createState() => _SwipeActionWrapperState();
}

class _SwipeActionWrapperState extends State<SwipeActionWrapper> with TickerProviderStateMixin {

  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  late AnimationController _confirmController;
  late Animation<double> _confirmAnimation;

  double _rawDragDistance = 0.0;
  double _currentVisualOffset = 0.0;

  double _dragStartPosition = 0.0;
  bool _isDeleting = false;
  bool _isConfirmingDelete = false;

  ListProvider? _provider;

  double get _menuSnapWidth => MediaQuery.of(context).size.width * AppPhysics.menuWidth;

  double get _activeSwallowSpeed => (_dragStartPosition.abs() < 1.0)
      ? AppPhysics.continuousSwallowSpeed
      : AppPhysics.swallowSpeed;

  bool get _isSwallowComplete {
    final double exposedWidth = _currentVisualOffset.abs();
    if (exposedWidth <= _menuSnapWidth) return false;

    final double deleteSlotWidth = _menuSnapWidth * AppPhysics.deleteSlotRatio;
    final double extraVisualDrag = exposedWidth - _menuSnapWidth;
    final double deleteWidth = deleteSlotWidth + (extraVisualDrag * _activeSwallowSpeed);

    return deleteWidth >= exposedWidth;
  }

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppPhysics.snapDurationMs),
    );
    _snapController.addListener(() {
      setState(() {
        _currentVisualOffset = _snapAnimation.value;
      });
    });

    _confirmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _confirmAnimation = CurvedAnimation(parent: _confirmController, curve: Curves.easeOutQuart);
    _confirmController.addListener(() {
      setState(() {});
    });
  }

  // NEW: Safely hook into the global provider state without triggering heavy rebuilds
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = Provider.of<ListProvider>(context, listen: false);
    if (_provider != newProvider) {
      _provider?.openSwipeItemId.removeListener(_onGlobalStateChanged);
      _provider = newProvider;
      _provider?.openSwipeItemId.addListener(_onGlobalStateChanged);
    }
  }

  @override
  void dispose() {
    _provider?.openSwipeItemId.removeListener(_onGlobalStateChanged);
    _snapController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // NEW: The auto-close trigger
  void _onGlobalStateChanged() {
    if (_provider?.openSwipeItemId.value != widget.itemId && _currentVisualOffset != 0.0) {
      _snapTo(0.0);
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (_snapController.isAnimating) {
      _snapController.stop();
    }

    // NEW: Claim the global open state, instantly closing any other open cards
    _provider?.openSwipeItemId.value = widget.itemId;

    if (_isConfirmingDelete) {
      setState(() {
        _isConfirmingDelete = false;
      });
      _confirmController.reverse();
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
        _currentVisualOffset = -(_menuSnapWidth + (overDrag * AppPhysics.frictionYield));
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isDeleting) return;

    final double velocity = details.primaryVelocity ?? 0.0;
    final double distanceDragged = (_rawDragDistance - _dragStartPosition).abs();

    final bool isFlingingLeft = velocity < -AppPhysics.flickVelocity && distanceDragged >= AppPhysics.flickMinDistance;
    final bool isFlingingRight = velocity > AppPhysics.flickVelocity && distanceDragged >= AppPhysics.flickMinDistance;

    final bool crossedHalfway = _currentVisualOffset.abs() > (_menuSnapWidth * 0.5);

    if (_isSwallowComplete) {
      if (widget.requireConfirm) {
        setState(() {
          _isConfirmingDelete = true;
        });
        _confirmController.forward();
        _snapTo(-_menuSnapWidth);
      } else {
        setState(() {
          _isDeleting = true;
        });
        widget.onDelete();
        _snapTo(0.0);
      }
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
    if (targetOffset == 0.0 && _isConfirmingDelete) {
      setState(() {
        _isConfirmingDelete = false;
      });
      _confirmController.reverse();
    }

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

    final double deleteSlotWidth = _menuSnapWidth * AppPhysics.deleteSlotRatio;
    final double editSlotWidth = _menuSnapWidth * AppPhysics.editSlotRatio;

    double baseDeleteWidth = 0.0;
    if (_isDeleting) {
      baseDeleteWidth = exposedWidth;
    } else if (exposedWidth <= _menuSnapWidth) {
      baseDeleteWidth = exposedWidth * AppPhysics.deleteSlotRatio;
    } else {
      final double extraVisualDrag = exposedWidth - _menuSnapWidth;
      baseDeleteWidth = deleteSlotWidth + (extraVisualDrag * _activeSwallowSpeed);
    }
    baseDeleteWidth = baseDeleteWidth.clamp(0.0, exposedWidth);

    final double deleteWidth = baseDeleteWidth + ((exposedWidth - baseDeleteWidth) * _confirmAnimation.value);

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
                          if (!_isDeleting && !_isConfirmingDelete) {
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
                              if (widget.requireConfirm && !_isConfirmingDelete) {
                                setState(() {
                                  _isConfirmingDelete = true;
                                });
                                _confirmController.forward();
                              } else {
                                setState(() {
                                  _isDeleting = true;
                                });
                                widget.onDelete();
                                _snapTo(0.0);
                              }
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
                                    right: (deleteSlotWidth / 2) - 12.0,
                                    top: 0,
                                    bottom: 0,
                                    child: Opacity(
                                      opacity: (1.0 - _confirmAnimation.value).clamp(0.0, 1.0),
                                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 24.0),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: exposedWidth,
                                    child: IgnorePointer(
                                      child: Opacity(
                                        opacity: _confirmAnimation.value.clamp(0.0, 1.0),
                                        child: const Center(
                                          child: Text(
                                            'Confirm Delete',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.0,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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