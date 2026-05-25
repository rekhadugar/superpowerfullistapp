import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:provider/provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';

class SwipeActionWrapper extends StatefulWidget {
  final Widget child;
  final String itemId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCheckout;
  final bool requireConfirm;
  final bool isBatchModeActive; // Receives strict batch state

  const SwipeActionWrapper({
    Key? key,
    required this.child,
    required this.itemId,
    required this.onEdit,
    required this.onDelete,
    required this.onCheckout,
    this.requireConfirm = true,
    this.isBatchModeActive = false,
  }) : super(key: key);

  @override
  State<SwipeActionWrapper> createState() => _SwipeActionWrapperState();
}

class _SwipeActionWrapperState extends State<SwipeActionWrapper> with TickerProviderStateMixin {
  late AnimationController _offsetController;
  late AnimationController _confirmController;
  late Animation<double> _confirmAnimation;

  double _rawDragDistance = 0.0;
  double _currentVisualOffset = 0.0;

  bool _isExecutingAction = false;
  bool _isConfirmingDelete = false;

  ListProvider? _provider;

  double get _menuSnapWidth => MediaQuery.of(context).size.width * AppPhysics.menuWidth;
  double get _checkoutThreshold => MediaQuery.of(context).size.width * AppPhysics.checkoutThreshold;

  @override
  void initState() {
    super.initState();

    // FIXED: Added fallback duration to prevent .reverse() crashes
    _offsetController = AnimationController.unbounded(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _offsetController.addListener(() {
      setState(() {
        _currentVisualOffset = _offsetController.value;
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
  void didUpdateWidget(SwipeActionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBatchModeActive && !oldWidget.isBatchModeActive) {
      if (_currentVisualOffset != 0.0) {
        _forceCloseMenu();
      }
    }
  }

  @override
  void dispose() {
    _provider?.openSwipeItemId.removeListener(_onGlobalStateChanged);
    _offsetController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onGlobalStateChanged() {
    if (_provider?.openSwipeItemId.value != widget.itemId && _currentVisualOffset != 0.0) {
      _snapTo(0.0, 0.0);
    }
  }

  // FIXED: Hard reset helper to prevent Zombie state leaks
  void _forceCloseMenu() {
    if (_offsetController.isAnimating) _offsetController.stop();
    _offsetController.value = 0.0;
    _currentVisualOffset = 0.0;
    _isConfirmingDelete = false;
    _isExecutingAction = false;
    if (_provider?.openSwipeItemId.value == widget.itemId) {
      _provider?.openSwipeItemId.value = null;
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (widget.isBatchModeActive) return; // Immobilize during batch selection

    // Instantly close the Fluid Edit popup if a swipe begins
    if (_provider?.editItemId != null) {
      _provider?.setEditItem(null);
    }

    if (_offsetController.isAnimating) {
      _offsetController.stop();
    }

    _provider?.openSwipeItemId.value = widget.itemId;

    if (_isConfirmingDelete) {
      setState(() {
        _isConfirmingDelete = false;
      });
      _confirmController.reverse();
    }

    _rawDragDistance = _currentVisualOffset;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.isBatchModeActive || _isExecutingAction) return;

    setState(() {
      _rawDragDistance += details.delta.dx;

      double calculatedOffset = 0.0;

      if (_rawDragDistance > 0) {
        if (_rawDragDistance <= _checkoutThreshold) {
          calculatedOffset = _rawDragDistance;
        } else {
          final overDrag = _rawDragDistance - _checkoutThreshold;
          calculatedOffset = _checkoutThreshold + (overDrag * AppPhysics.frictionYield);
        }
      } else {
        if (_rawDragDistance.abs() <= _menuSnapWidth) {
          calculatedOffset = _rawDragDistance;
        } else {
          final overDrag = _rawDragDistance.abs() - _menuSnapWidth;
          calculatedOffset = -(_menuSnapWidth + (overDrag * AppPhysics.frictionYield));
        }
      }

      _offsetController.value = calculatedOffset;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.isBatchModeActive || _isExecutingAction) return;

    final double velocity = details.primaryVelocity ?? 0.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double projectedOffset = _currentVisualOffset + (velocity * AppPhysics.momentumMultiplier);

    // === RIGHT SWIPE (Checkout) ===
    if (_currentVisualOffset > 0) {
      final double checkoutTriggerPoint = screenWidth * AppPhysics.checkoutThreshold;

      if (projectedOffset >= checkoutTriggerPoint) {
        _glideOffScreen(screenWidth, velocity, () {
          _forceCloseMenu(); // Prevent UI lock
          widget.onCheckout();
        });
      } else {
        _snapTo(0.0, velocity);
      }
      return;
    }

    // === LEFT SWIPE (Menu / Delete) ===
    final double deleteTriggerPoint = -(screenWidth * AppPhysics.swipeExecuteThreshold);
    final double menuTriggerPoint = -(_menuSnapWidth * 0.5);

    if (projectedOffset <= deleteTriggerPoint) {
      if (widget.requireConfirm) {
        setState(() => _isConfirmingDelete = true);
        _confirmController.forward();
        _snapTo(-_menuSnapWidth, velocity);
      } else {
        _glideOffScreen(-screenWidth, velocity, () {
          _forceCloseMenu(); // Prevent UI lock
          widget.onDelete();
        });
      }
    } else if (projectedOffset <= menuTriggerPoint) {
      _snapTo(-_menuSnapWidth, velocity);
    } else {
      _snapTo(0.0, velocity);
    }
  }

  void _snapTo(double targetOffset, double velocity) {
    if (targetOffset == 0.0 && _isConfirmingDelete) {
      setState(() => _isConfirmingDelete = false);
      _confirmController.reverse();
    }

    final simulation = SpringSimulation(
      const SpringDescription(
        mass: AppPhysics.springMass,
        stiffness: AppPhysics.springStiffness,
        damping: AppPhysics.springDamping,
      ),
      _offsetController.value,
      targetOffset,
      velocity,
    );

    // FIXED: Clean out physics math to defeat microscopic floating point errors locking the UI
    _offsetController.animateWith(simulation).then((_) {
      if (!mounted) return;
      _offsetController.value = targetOffset;
      _currentVisualOffset = targetOffset;
      if (targetOffset == 0.0 && _provider?.openSwipeItemId.value == widget.itemId) {
        _provider?.openSwipeItemId.value = null;
      }
    });
  }

  void _glideOffScreen(double targetOffset, double velocity, VoidCallback onComplete) {
    setState(() => _isExecutingAction = true);

    if (targetOffset == 0.0 && _isConfirmingDelete) {
      setState(() => _isConfirmingDelete = false);
      _confirmController.reverse();
    }

    _offsetController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutSine,
    ).then((_) {
      onComplete();
      _offsetController.value = 0.0;
      if (mounted) {
        setState(() => _isExecutingAction = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double exposedWidth = _currentVisualOffset.abs();
    final bool isRightSwipe = _currentVisualOffset > 0;

    final double deleteSlotWidth = _menuSnapWidth * AppPhysics.deleteSlotRatio;
    final double editSlotWidth = _menuSnapWidth * AppPhysics.editSlotRatio;

    double baseDeleteWidth = 0.0;
    if (_isExecutingAction && !isRightSwipe) {
      baseDeleteWidth = exposedWidth;
    } else if (exposedWidth <= _menuSnapWidth) {
      baseDeleteWidth = exposedWidth * AppPhysics.deleteSlotRatio;
    } else {
      final double executeThresholdPixels = screenWidth * AppPhysics.swipeExecuteThreshold;
      final double distanceToThreshold = executeThresholdPixels - _menuSnapWidth;

      final double dynamicSwallowSpeed = distanceToThreshold > 0
          ? ((executeThresholdPixels - deleteSlotWidth) / distanceToThreshold)
          : 1.0;

      final double extraVisualDrag = exposedWidth - _menuSnapWidth;
      baseDeleteWidth = deleteSlotWidth + (extraVisualDrag * dynamicSwallowSpeed);
    }

    baseDeleteWidth = baseDeleteWidth.clamp(0.0, exposedWidth);
    final double deleteWidth = baseDeleteWidth + ((exposedWidth - baseDeleteWidth) * _confirmAnimation.value);

    final bool isCheckoutReady = _rawDragDistance >= _checkoutThreshold;

    // FIXED: Safe floating point threshold check for the UI blocker
    final bool isMenuOpen = exposedWidth > 0.1;

    // RESTORED YOUR ORIGINAL UI LAYOUT
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppConstants.cardMargin),
            child: ClipRect(
              child: isRightSwipe
                  ? Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: exposedWidth,
                  child: Container(
                    color: const Color(0xFF34C759),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 24.0,
                          top: 0,
                          bottom: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: isCheckoutReady ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: const Icon(Icons.check_circle, color: Colors.white, size: 28.0),
                              ),
                              const SizedBox(width: 12.0),
                              AnimatedOpacity(
                                opacity: isCheckoutReady ? 1.0 : 0.6,
                                duration: const Duration(milliseconds: 150),
                                child: const Text(
                                    'Check Out',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16.0)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  : Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: exposedWidth,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (!_isExecutingAction && !_isConfirmingDelete) {
                            _forceCloseMenu(); // Prevent UI Lock
                            widget.onEdit();
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
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: deleteWidth,
                        child: GestureDetector(
                          onTap: () {
                            if (!_isExecutingAction) {
                              if (widget.requireConfirm && !_isConfirmingDelete) {
                                setState(() {
                                  _isConfirmingDelete = true;
                                });
                                _confirmController.forward();
                              } else {
                                setState(() {
                                  _isExecutingAction = true;
                                });
                                _forceCloseMenu(); // Prevent UI Lock
                                widget.onDelete();
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
                                            'Tap To Delete',
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

            // FIXED: Safe threshold check & _snapTo to prevent crashes
            onTap: isMenuOpen ? () {
              _snapTo(0.0, 0.0);
              if (widget.itemId == _provider?.openSwipeItemId.value) {
                _provider?.openSwipeItemId.value = null;
              }
            } : null,
            behavior: HitTestBehavior.opaque,

            // FIXED: Safe threshold check
            child: AbsorbPointer(
              absorbing: isMenuOpen,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}